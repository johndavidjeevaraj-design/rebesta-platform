import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';
import { SocketGateway } from '../socket/socket.gateway';
import { CreateOrderDto } from './dto/create-order.dto';
import { MapsService } from '../maps/maps.service';
import { FcmService } from '../fcm/fcm.service';
import { CouponsService } from '../coupons/coupons.service';

@Injectable()
export class OrdersService {
  constructor(
    private readonly mapsService: MapsService,
    private readonly socketGateway: SocketGateway,
    private readonly fcmService: FcmService,
    private readonly couponsService: CouponsService,
  ) {}

  // ============================================================
  // CHECKOUT
  // ============================================================

  async checkout(
    customerId: string,
    dto: CreateOrderDto,
  ) {
    // ==========================================================
    // GET CART
    // ==========================================================

    const {
      data: cart,
      error: cartError,
    } = await supabase
      .from('carts')
      .select(`
        *,
        cart_items(
          id,
          menu_item_id,
          quantity,
          price
        )
      `)
      .eq('customer_id', customerId)
      .eq(
        'restaurant_partner_id',
        dto.restaurantPartnerId,
      )
      .order('created_at', {
        ascending: false,
      })
      .limit(1)
      .maybeSingle();

    if (cartError) {
      throw new Error(
        `Cart lookup failed: ${cartError.message}`,
      );
    }

    if (!cart) {
      throw new Error('Cart not found');
    }

    // ==========================================================
    // GET CART ITEMS
    // ==========================================================

    const cartItems = Array.isArray(cart.cart_items)
      ? cart.cart_items
      : [];

    if (cartItems.length === 0) {
      throw new Error('Cart is empty');
    }

    // ==========================================================
// CALCULATE SUBTOTAL
//
// Must happen BEFORE delivery fee calculation because the
// delivery fee engine uses subtotal for:
// - small-order surcharge
// - free delivery threshold
// ==========================================================

let subtotal = 0;

for (const item of cartItems) {
  subtotal +=
    Number(item.quantity ?? 0) *
    Number(item.price ?? 0);
}

    // ==========================================================
    // GET DELIVERY ADDRESS WITH COORDINATES
    // ==========================================================

    const {
      data: address,
      error: addressError,
    } = await supabase
      .from('addresses')
      .select('id, latitude, longitude')
      .eq('id', dto.addressId)
      .eq('user_id', customerId)
      .single();

    if (addressError || !address) {
      throw new Error(
        'Invalid delivery address',
      );
    }

    // ==========================================================
    // GET RESTAURANT COORDINATES
    //
    // NOTE: coordinates live on the `restaurants` table
    // (keyed by restaurant_partner_id), not `restaurant_partners`.
    // ==========================================================

    const {
      data: restaurant,
      error: restaurantLookupError,
    } = await supabase
      .from('restaurants')
      .select('latitude, longitude')
      .eq('restaurant_partner_id', dto.restaurantPartnerId)
      .maybeSingle();

    if (restaurantLookupError) {
      throw new Error(restaurantLookupError.message);
    }

// ==========================================================
// CALCULATE DELIVERY FEE
//
// ONE fee engine for COD + online + cart estimates.
//
// Real road distance via ORS
// → straight-line fallback
// → base fee when coordinates are unavailable.
//
// The MapsService also handles:
// - included distance
// - per-km pricing
// - peak surcharge
// - small-order surcharge
// - free delivery threshold
// - maximum fee
// ==========================================================

const feeResult =
  await this.mapsService.calculateOrderDeliveryFee({
    restaurantLat:
      restaurant?.latitude != null
        ? Number(restaurant.latitude)
        : null,

    restaurantLng:
      restaurant?.longitude != null
        ? Number(restaurant.longitude)
        : null,

    addressLat:
      address?.latitude != null
        ? Number(address.latitude)
        : null,

    addressLng:
      address?.longitude != null
        ? Number(address.longitude)
        : null,

    subtotal,

    orderType: 'delivery',

    includeWeather: true,
  });

const deliveryFee = feeResult.fee;

console.log('====================================');
console.log('💰 COD DELIVERY FEE');
console.log('Subtotal:', subtotal);
console.log('Distance:', feeResult.distanceKm, 'km');
console.log('Delivery Fee:', deliveryFee);
console.log('Breakdown:', feeResult.breakdown);
console.log('====================================');

    // ==========================================================
    // COUPON
    // ==========================================================

    let discount = 0;

    if (
      dto.couponCode &&
      dto.couponCode.trim().length > 0
    ) {
      const {
        data: coupon,
      } = await supabase
        .from('coupons')
        .select(`
          id,
          used_count
        `)
        .eq(
          'code',
          dto.couponCode.toUpperCase(),
        )
        .maybeSingle();

      if (coupon) {
        // Coupon calculation can be
        // implemented here later.
        discount = 0;
      }
    }

// ==========================================================
// CALCULATE TOTAL
// ==========================================================

const totalAmount =
  subtotal +
  deliveryFee -
  discount;

    if (totalAmount <= 0) {
      throw new Error(
        'Invalid order amount',
      );
    }

    // ==========================================================
    // DELIVERY OTP
    // ==========================================================

    const deliveryOtp =
      Math.floor(
        1000 + Math.random() * 9000,
      ).toString();

    // ==========================================================
    // CREATE PENDING ORDER
    // ==========================================================

    const {
      data: order,
      error: orderError,
    } = await supabase
      .from('orders')
      .insert({
        customer_id: customerId,

        restaurant_partner_id:
          cart.restaurant_partner_id,

        address_id:
          dto.addressId,

        discount_amount:
          discount,

        delivery_fee:
          deliveryFee,

        total_amount:
          totalAmount,

        payment_status:
          'pending',

        order_status:
          'pending',

        delivery_otp:
          deliveryOtp,

        otp_verified:
          false,
      })
      .select()
      .single();

    if (orderError || !order) {
      throw new Error(
        orderError?.message ??
          'Failed to create order',
      );
    }

    // ==========================================================
    // CREATE ORDER ITEMS
    // ==========================================================

    const orderItems = cartItems.map(
      (item: any) => ({
        order_id: order.id,

        menu_id:
          item.menu_item_id,

        quantity:
          item.quantity,

        price:
          item.price,
      }),
    );

    const {
      error: itemError,
    } = await supabase
      .from('order_items')
      .insert(orderItems);

    if (itemError) {
      // Roll back order if items fail.
      await supabase
        .from('orders')
        .delete()
        .eq('id', order.id);

      throw new Error(
        itemError.message,
      );
    }

    // ==========================================================
// LIVE RESTAURANT ORDER EVENT
// ==========================================================

try {
  this.socketGateway.emitToPartner(
    order.restaurant_partner_id,
    'new_order',
    {
      orderId: order.id,
      status: order.order_status,
      paymentStatus: order.payment_status,
      totalAmount: order.total_amount,
    },
  );

  console.log(
    '📡 New order event sent to partner:',
    order.restaurant_partner_id,
    order.id,
  );
} catch (socketError) {
  console.error(
    '❌ Failed to send new order socket event:',
    socketError,
  );
}

// ==========================================================
// NOTIFY RESTAURANT PARTNER — FCM
// ==========================================================

try {
  await this.fcmService.sendToPartner(
    dto.restaurantPartnerId,
    '🍽️ New Order',
    'You have received a new order.',
    {
      orderId: order.id,
      status: 'pending',
      screen: 'orders',
    },
  );

  console.log(
    '🔔 New order FCM sent to partner:',
    dto.restaurantPartnerId,
  );
} catch (error) {
  console.error(
    '❌ Partner FCM notification failed:',
    error,
  );
}
    // ==========================================================
    // IMPORTANT
    //
    // DO NOT CLEAR CART HERE.
    // PAYMENT MUST HAPPEN FIRST.
    // ==========================================================

    return {
      success: true,

      message:
        'Order created. Payment required.',

      order: {
        id: order.id,

        subtotal: subtotal,

        deliveryFee: deliveryFee,

        discount: discount,

        total:
          order.total_amount,

        status:
          order.order_status,

        paymentStatus:
          order.payment_status,

        deliveryOtp:
          deliveryOtp,

        otpVerified:
          false,
      },
    };
  }

  // ============================================================
  // CUSTOMER ORDERS
  // ============================================================

  async getCustomerOrders(
    customerId: string,
  ) {
    const {
      data,
      error,
    } = await supabase
      .from('orders')
      .select(`
        id,
        total_amount,
        payment_status,
        order_status,
        created_at,

        order_items(
          quantity,
          price,

          menu_items(
            name,
            image_url
          )
        )
      `)
      .eq(
        'customer_id',
        customerId,
      )
      .order(
        'created_at',
        {
          ascending: false,
        },
      );

    if (error) {
      throw new Error(
        error.message,
      );
    }

    return {
      success: true,
      orders: data ?? [],
    };
  }

  // ============================================================
  // ORDER DETAILS
  // ============================================================

  async getOrderById(
    customerId: string,
    orderId: string,
  ) {
    const {
      data,
      error,
    } = await supabase
      .from('orders')
      .select(`
        *,

        restaurant_partners(
          id,
          restaurant_name,
          logo_url
        ),

        order_items(
          quantity,
          price,

          menu_items(
            name,
            image_url,
            description,
            is_veg
          )
        )
      `)
      .eq(
        'id',
        orderId,
      )
      .eq(
        'customer_id',
        customerId,
      )
      .single();

    if (error || !data) {
      throw new Error(
        'Order not found',
      );
    }

    return {
      success: true,
      order: data,
    };
  }

  // ============================================================
  // TRACK ORDER
  // ============================================================

  async trackOrder(
  customerId: string,
  orderId: string,
) {
  // ==========================================================
  // GET ORDER
  // ==========================================================

  const {
    data: order,
    error,
  } = await supabase
    .from('orders')
    .select(`
      id,
      address_id,
      order_status,
      total_amount,
      discount_amount,
      delivery_fee,
      payment_status,
      created_at,
      assigned_at,
      picked_up_at,
      out_for_delivery_at,
      delivered_at,

      restaurant_partners(
        id,
        restaurant_name,
        address
      ),

      delivery_partners(
        id,
        name,
        mobile,
        vehicle_type,
        vehicle_number,
        current_latitude,
        current_longitude,
        last_location_updated_at,
        completed_deliveries,
        rating,
        total_reviews
      ),

      order_items(
        quantity,
        price,

        menu_items(
          name,
          image_url,
          is_veg
        )
      )
    `)
    .eq('id', orderId)
    .eq('customer_id', customerId)
    .single();

  if (error || !order) {
    console.error('TRACK ORDER ERROR:', error);
    throw new Error('Order not found');
  }

  // ==========================================================
  // GET DELIVERY ADDRESS DIRECTLY
  // ==========================================================

  let address: any = null;

  if (order.address_id) {
    const {
      data: addressData,
      error: addressError,
    } = await supabase
      .from('addresses')
      .select(`
        id,
        address,
        latitude,
        longitude
      `)
      .eq('id', order.address_id)
      .eq('user_id', customerId)
      .maybeSingle();

    if (addressError) {
      console.error(
        'TRACK ADDRESS ERROR:',
        addressError,
      );
    }

    address = addressData;
  }

  console.log('====================================');
  console.log('📍 TRACKING DESTINATION');
  console.log('Address ID:', order.address_id);
  console.log('Destination:', address);
  console.log('====================================');

  // ==========================================================
  // RIDER
  // ==========================================================

  const rider: any =
    Array.isArray(order.delivery_partners)
      ? order.delivery_partners[0]
      : order.delivery_partners;

  console.log('====================================');
  console.log('🚴 TRACKING RIDER');
  console.log('Rider:', rider);
  console.log('====================================');

  // ==========================================================
  // ETA / ROAD ROUTE
  // ==========================================================

  let eta: any = null;

  if (
    rider &&
    address &&
    rider.current_latitude != null &&
    rider.current_longitude != null &&
    address.latitude != null &&
    address.longitude != null
  ) {
    try {
      console.log('====================================');
      console.log('🛣️ CALCULATING RIDER → CUSTOMER ROUTE');
      console.log(
        'Rider:',
        rider.current_latitude,
        rider.current_longitude,
      );
      console.log(
        'Customer:',
        address.latitude,
        address.longitude,
      );
      console.log('====================================');

      eta = await this.mapsService.getETA(
        Number(rider.current_latitude),
        Number(rider.current_longitude),
        Number(address.latitude),
        Number(address.longitude),
      );

      console.log('====================================');
      console.log('✅ ROAD ROUTE RESULT');
      console.log('ETA:', eta);
      console.log('====================================');
    } catch (error) {
      console.error(
        'ETA calculation failed:',
        error,
      );

      eta = null;
    }
  } else {
    console.log('====================================');
    console.log('⚠️ CANNOT CALCULATE ROUTE');
    console.log('Rider:', rider);
    console.log('Address:', address);
    console.log('====================================');
  }

  // ==========================================================
  // RETURN TRACKING DATA
  // ==========================================================

  return {
    success: true,

    tracking: {
      orderId: order.id,

      status: order.order_status,

      totalAmount: order.total_amount,

      discountAmount: order.discount_amount,

      deliveryFee: order.delivery_fee,

      paymentStatus: order.payment_status,

      restaurant: order.restaurant_partners,

      rider: rider
        ? {
            id: rider.id,
            name: rider.name,
            mobile: rider.mobile,
            vehicleType: rider.vehicle_type,
            vehicleNumber: rider.vehicle_number,
            currentLatitude: rider.current_latitude,
            currentLongitude: rider.current_longitude,
            lastLocationUpdatedAt:
              rider.last_location_updated_at,
            completedDeliveries:
              rider.completed_deliveries,
            rating: rider.rating,
            totalReviews: rider.total_reviews,
          }
        : null,

      items: order.order_items ?? [],

      // IMPORTANT:
      // Directly fetched customer destination.
      destination: address,

      eta,

      createdAt: order.created_at,

      assignedAt: order.assigned_at,

      pickedUpAt: order.picked_up_at,

      outForDeliveryAt:
        order.out_for_delivery_at,

      deliveredAt: order.delivered_at,
    },
  };
}
}