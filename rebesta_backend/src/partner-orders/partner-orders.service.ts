import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationTemplates } from '../notifications/notification.templates';
import { SocketGateway } from '../socket/socket.gateway';
import { FcmService } from '../fcm/fcm.service';

@Injectable()
export class PartnerOrdersService {

  constructor(
  private readonly notificationsService: NotificationsService,
  private readonly socketGateway: SocketGateway,
   private readonly fcmService: FcmService
) {}

  // Get restaurant orders
  async getPartnerOrders(
  restaurantPartnerId: string,
) {

  console.log('========================================');
  console.log('GET PARTNER ORDERS');
  console.log('Restaurant Partner ID:', restaurantPartnerId);
  console.log('========================================');

  const { data: orders, error } =
    await supabase
      .from('orders')
      .select(`
        id,
        total_amount,
        payment_status,
        order_status,
        created_at,
        customer_id,

        customers (
          id,
          name,
          mobile
        ),

        order_items (
          id,
          quantity,
          price,

          menu_items (
            id,
            name,
            description,
            image_url,
            is_veg
          )
        )
      `)
      .eq(
        'restaurant_partner_id',
        restaurantPartnerId,
      )
      .order(
        'created_at',
        {
          ascending: false,
        },
      );

  console.log('========================================');
  console.log('PARTNER ORDERS RESULT');
  console.log('Supabase Error:', error);
  console.log('Orders Count:', orders?.length ?? 0);
  console.log('Orders:', JSON.stringify(orders, null, 2));
  console.log('========================================');

  if (error) {
    throw new Error(error.message);
  }

  const formattedOrders = (orders ?? []).map(
    (order: any) => ({
      id: order.id,

      totalAmount: order.total_amount,

      paymentStatus: order.payment_status,

      orderStatus: order.order_status,

      createdAt: order.created_at,

      customer:
        Array.isArray(order.customers)
          ? order.customers[0]
          : order.customers,

      items: (order.order_items ?? []).map(
        (item: any) => {

          const menu =
            Array.isArray(item.menu_items)
              ? item.menu_items[0]
              : item.menu_items;

          return {
            id: menu?.id,
            name: menu?.name,
            description: menu?.description,
            imageUrl: menu?.image_url,
            isVeg: menu?.is_veg,
            quantity: item.quantity,
            price: item.price,
            subtotal:
              item.quantity * item.price,
          };
        },
      ),
    }),
  );

  console.log('FORMATTED ORDERS COUNT:', formattedOrders.length);

  return {
    success: true,
    orders: formattedOrders,
  };
}





 // ===============================
// Update Order Status
// ===============================
async updateStatus(
  orderId: string,
  newStatus: string,
  restaurantPartnerId: string,
) {

  // Get current order

  const { data: order, error: findError } =
    await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        order_status,
        restaurant_partner_id
      `)
      .eq('id', orderId)
      .eq(
        'restaurant_partner_id',
        restaurantPartnerId,
      )
      .single();

  if (findError || !order) {

    throw new Error(
      'Order not found',
    );

  }

  // Allowed state transitions

  const transitions: Record<string, string[]>  = {

    pending: [
      'accepted',
      'cancelled',
    ],

    accepted: [
      'ready',
      'cancelled',
    ],

    preparing: [],

    ready: [],

    assigned: [],

    picked_up: [],

    out_for_delivery: [],

    delivered: [],

    cancelled: [],

  };

  const allowed =
    transitions[
      order.order_status
    ] || [];

  if (
    !allowed.includes(newStatus)
  ) {

    throw new Error(
      `Cannot change order from "${order.order_status}" to "${newStatus}"`,
    );

  }

  // Update status

  const { data, error } =
    await supabase
      .from('orders')
      .update({

        order_status:
          newStatus,

      })
      .eq('id', orderId)
      .select()
      .single();


  if (error) {

    throw new Error(
      error.message,
    );

  }

        // Live Socket Update
// ============================================================
// LIVE SOCKET UPDATE
// ============================================================

try {
  this.socketGateway.sendOrderUpdate(
    orderId,
    newStatus,
  );

  this.socketGateway.emitToCustomer(
    data.customer_id,
    'order_status',
    {
      orderId: data.id,
      status: newStatus,
    },
  );

  console.log(
    'Socket order status update sent:',
    orderId,
    newStatus,
  );
} catch (socketError) {
  console.error(
    'Socket notification failed:',
    socketError,
  );
}
  // ===============================
// Automatic Customer Notification
// ===============================


// ============================================================
// CUSTOMER NOTIFICATION
// ============================================================

let title = '';
let message = '';

switch (newStatus) {
  case 'accepted':
    title = '🍽️ Order Accepted';
    message = 'Your order has been accepted and is being prepared';
    break;

  case 'ready':
    title = '📦 Order Ready';
    message =
        'Your order is ready and waiting for pickup.';
    break;

}

// Notifications must NEVER cause the order-status API to fail.

if (title) {
  try {
    await this.notificationsService.create({
      customerId: order.customer_id,
      title,
      message,
      type: 'order',
      deepLink: `/orders/${order.id}`,
    });

    console.log(
      'Customer notification created successfully',
    );
  } catch (notificationError) {
    console.error(
      'Customer notification failed:',
      notificationError,
    );
  }

  try {
    await this.fcmService.sendToCustomer(
      order.customer_id,
      title,
      message,
      {
        orderId: order.id,
        status: newStatus,
        screen: 'order_details',
      },
    );

    console.log(
      'Customer FCM notification sent successfully',
    );
  } catch (fcmError) {
    console.error(
      'Customer FCM notification failed:',
      fcmError,
    );
  }
}

// ============================================================
// RETURN SUCCESS
// ============================================================

return {
  success: true,

  message:
      'Order status updated successfully',

  order: data,
};

}
// ===============================
// Get Single Order Details
// ===============================
async getOrderById(
  orderId: string,
  restaurantPartnerId: string,
) {

  const { data: order, error } =
    await supabase
      .from('orders')
      .select(`
        id,
        total_amount,
        payment_status,
        order_status,
        created_at,

        customers (
          id,
          name,
          mobile
        ),

        addresses (
          id,
          title,
          address,
          landmark,
          city,
          state,
          pincode,
          latitude,
          longitude
        ),

        order_items (
          quantity,
          price,

          menu_items (
            id,
            name,
            description,
            image_url,
            is_veg
          )
        )
      `)
      .eq('id', orderId)
      .eq('restaurant_partner_id', restaurantPartnerId)
      .single();

  if (error || !order) {
    throw new Error('Order not found');
  }

  const customer = Array.isArray(order.customers)
    ? order.customers[0]
    : order.customers;

  const address = Array.isArray(order.addresses)
    ? order.addresses[0]
    : order.addresses;

  const items = order.order_items.map((item: any) => {

    const menu = Array.isArray(item.menu_items)
      ? item.menu_items[0]
      : item.menu_items;

    return {

      id: menu?.id,

      name: menu?.name,

      description: menu?.description,

      imageUrl: menu?.image_url,

      isVeg: menu?.is_veg,

      quantity: item.quantity,

      price: item.price,

      subtotal: item.quantity * item.price,

    };

  });

  return {

    success: true,

    order: {

      id: order.id,

      totalAmount: order.total_amount,

      paymentStatus: order.payment_status,

      orderStatus: order.order_status,

      createdAt: order.created_at,

      customer: {

        id: customer?.id,

        name: customer?.name,

        mobile: customer?.mobile,

      },

      deliveryAddress: {

        id: address?.id,

        title: address?.title,

        address: address?.address,

        landmark: address?.landmark,

        city: address?.city,

        state: address?.state,

        pincode: address?.pincode,

        latitude: address?.latitude,

        longitude: address?.longitude,

      },

      items,

    },

  };

}

}