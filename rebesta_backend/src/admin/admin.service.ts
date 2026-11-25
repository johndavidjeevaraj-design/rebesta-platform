import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { supabase } from '../supabase';
import { StorageService } from '../storage/storage.service';
import { PaymentsService } from '../payments/payments.service';

@Injectable()
export class AdminService {

  constructor(
    private readonly storageService: StorageService,
    private readonly paymentsService: PaymentsService,
  ) {}

  // ==========================
  // Dashboard
  // ==========================
  async getDashboard() {

    // Restaurants
    const { count: totalRestaurants } =
      await supabase
        .from('restaurant_partners')
        .select('*', { count: 'exact', head: true });

    // Pending Restaurants
    const { count: pendingRestaurants } =
      await supabase
        .from('restaurant_partners')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending');

    // Customers
    const { count: totalCustomers } =
      await supabase
        .from('customers')
        .select('*', { count: 'exact', head: true });

    // Delivery Partners
    const { count: totalDeliveryPartners } =
      await supabase
        .from('delivery_partners')
        .select('*', { count: 'exact', head: true });

    // Today's Orders
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const { data: todayOrders } =
      await supabase
        .from('orders')
        .select('total_amount')
        .gte('created_at', today.toISOString());

    const orderCount = todayOrders?.length ?? 0;

    const todayRevenue =
      todayOrders?.reduce(
        (sum, order) => sum + Number(order.total_amount),
        0,
      ) ?? 0;

    return {
      success: true,
      dashboard: {
        totalRestaurants: totalRestaurants ?? 0,
        pendingRestaurants: pendingRestaurants ?? 0,
        totalCustomers: totalCustomers ?? 0,
        totalDeliveryPartners: totalDeliveryPartners ?? 0,
        todayOrders: orderCount,
        todayRevenue,
      },
    };
  }

  async getRestaurants() {

  const { data, error } = await supabase
    .from('restaurant_partners')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) {
    throw new Error(error.message);
  }

  return {
    success: true,
    restaurants: data,
  };
}

async getRestaurant(id: string) {

  const { data, error } = await supabase
    .from('restaurant_partners')
    .select('*')
    .eq('id', id)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {
    success: true,
    restaurant: data,
  };
}

async approveRestaurant(id: string) {

  const { data, error } = await supabase
    .from('restaurant_partners')
    .update({
      status: 'approved',
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new ConflictException(`${entity} status changed or transition is not allowed`);
  }

  return {
    success: true,
    message: 'Restaurant approved',
    restaurant: data,
  };
}
async rejectRestaurant(id: string) {

  const { data, error } = await supabase
    .from('restaurant_partners')
    .update({
      status: 'rejected',
    })
    .eq('id', id)
    .eq('status', 'pending')
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new ConflictException(`${entity} status changed or transition is not allowed`);
  }

  return {
    success: true,
    message: 'Restaurant rejected',
    restaurant: data,
  };
}
async blockRestaurant(id: string) {

  const { data, error } = await supabase
    .from('restaurant_partners')
    .update({
      status: 'blocked',
    })
    .eq('id', id)
    .eq('status', 'approved')
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new ConflictException(`${entity} status changed or transition is not allowed`);
  }

  return {
    success: true,
    message: 'Restaurant blocked',
    restaurant: data,
  };
}
async unblockRestaurant(id: string) {

  const { data, error } = await supabase
    .from('restaurant_partners')
    .update({
      status: 'approved',
    })
    .eq('id', id)
    .eq('status', 'blocked')
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new ConflictException(`${entity} status changed or transition is not allowed`);
  }

  return {
    success: true,
    message: 'Restaurant unblocked',
    restaurant: data,
  };
}
// ==========================
// Get All Customers
// ==========================
async getCustomers() {

  // Fetch all customers
  const { data: customers, error } = await supabase
    .from('customers')
    .select(`
      id,
      name,
      email,
      mobile,
      created_at
    `)
    .order('created_at', {
      ascending: false,
    });

  if (error) {
    throw new Error(error.message);
  }

  const result: any[] = [];

  for (const customer of customers) {

    // Get customer's orders
    const { data: orders } = await supabase
      .from('orders')
      .select(`
        id,
        total_amount,
        created_at
      `)
      .eq('customer_id', customer.id);

    const totalOrders = orders?.length ?? 0;

    const totalSpent =
      orders?.reduce(
        (sum, order) =>
          sum + Number(order.total_amount),
        0,
      ) ?? 0;

    const lastOrder =
      orders && orders.length > 0
        ? orders.sort(
            (a, b) =>
              new Date(b.created_at).getTime() -
              new Date(a.created_at).getTime(),
          )[0].created_at
        : null;

    result.push({ 
        
         id: customer.id,

        name: customer.name,

        email: customer.email,

        mobile: customer.mobile,

        joinedAt: customer.created_at,

        totalOrders,

        totalSpent,

        lastOrderAt: lastOrder,

    });

  }

  return {

    success: true,

    totalCustomers: result.length,

    customers: result,

  };

}
// ==========================
// Get All Delivery Partners
// ==========================
async getDeliveryPartners() {

  const { data: partners, error } = await supabase
    .from('delivery_partners')
    .select(`
      id,
      name,
      email,
      mobile,
      vehicle_type,
      vehicle_number,
      profile_image,
      is_online,
      is_available,
      current_latitude,
      current_longitude,
      rating,
      total_deliveries,
      wallet_balance,
      total_earnings,
      pending_payout,
      completed_deliveries,
      created_at
    `)
    .order('created_at', {
      ascending: false,
    });

  if (error) {
    throw new Error(error.message);
  }

  const result: any[] = [];

  for (const partner of partners) {

    // Active Order
    const { data: activeOrder } = await supabase
      .from('orders')
      .select(`
        id,
        order_status,
        total_amount
      `)
      .eq('delivery_partner_id', partner.id)
      .in('order_status', [
        'accepted',
        'accepted_for_delivery',
        'picked_up',
        'out_for_delivery',
      ])
      .maybeSingle();


    result.push({

      id: partner.id,

      name: partner.name,

      email: partner.email,

      mobile: partner.mobile,

      vehicleType: partner.vehicle_type,

      vehicleNumber: partner.vehicle_number,

      profileImage: partner.profile_image,

      isOnline: partner.is_online,

      isAvailable: partner.is_available,

      currentLocation: {

        latitude: partner.current_latitude,

        longitude: partner.current_longitude,

      },

      rating: Number(partner.rating),

      totalDeliveries:
        partner.total_deliveries,

      totalCompletedOrders:
        partner.completed_deliveries ?? 0,

      walletBalance: Number(partner.wallet_balance ?? 0),

      pendingPayout: Number(partner.pending_payout ?? 0),

      totalEarnings: Number(partner.total_earnings ?? 0),

      activeOrder,

      joinedAt:
        partner.created_at,

    });

  }

  return {

    success: true,

    totalDeliveryPartners:
      result.length,

    deliveryPartners: result,

  };

}
async getDeliveryPartner(id: string) {

  const { data: partner, error } = await supabase
    .from('delivery_partners')
    .select('*')
    .eq('id', id)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  const { data: orders } = await supabase
    .from('orders')
    .select(`
      id,
      total_amount,
      order_status,
      created_at
    `)
    .eq('delivery_partner_id', id)
    .order('created_at', {
      ascending: false,
    });

  const { data: earnings, error: earningsError } = await supabase
    .from('delivery_earnings')
    .select('amount, status')
    .eq('delivery_partner_id', id);

  if (earningsError) {
    throw new Error(earningsError.message);
  }

  const lifetimeEarnings = (earnings ?? []).reduce(
    (sum, earning) => earning.status !== 'reversed'
      ? sum + Number(earning.amount)
      : sum,
    0,
  );
  const pendingPayout = (earnings ?? [])
    .filter((earning) => earning.status === 'pending')
    .reduce((sum, earning) => sum + Number(earning.amount), 0);

  return {

    success: true,

    partner,

    statistics: {

      totalOrders:
        orders?.length ?? 0,

      completedOrders:
        orders?.filter(
          o => o.order_status === 'delivered',
        ).length ?? 0,

      cancelledOrders:
        orders?.filter(
          o => o.order_status === 'cancelled',
        ).length ?? 0,

      activeOrders:
        orders?.filter(o =>
          [
            'accepted_for_delivery',
            'picked_up',
            'out_for_delivery',
            'arrived_at_customer',
          ].includes(o.order_status),
        ).length ?? 0,

      totalEarnings: lifetimeEarnings,

      pendingPayout,

      walletBalance: Number(partner.wallet_balance ?? 0),

    },

    recentOrders:
      orders?.slice(0, 10),

  };

}
async approveDeliveryPartner(id: string) {

  const { data, error } = await supabase
    .from('delivery_partners')
    .update({
      is_available: true,
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {

    success: true,

    message: 'Delivery partner approved',

    partner: data,

  };

}
async rejectDeliveryPartner(id: string) {

  const { data, error } = await supabase
    .from('delivery_partners')
    .update({
      is_available: false,
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {

    success: true,

    message: 'Delivery partner rejected',

    partner: data,

  };

}


async settleDeliveryPayout(id: string, payoutReference: string) {
  const { data, error } = await supabase.rpc('settle_delivery_payout', {
    p_partner_id: id,
    p_payout_reference: payoutReference,
  });

  if (error || !data?.payout) {
    throw new ConflictException(
      error?.message ?? 'Payout settlement failed',
    );
  }

  return {
    success: true,
    alreadyProcessed: data.already_processed === true,
    payout: data.payout,
  };
}

// ============================================================
// DELIVERY KYC REVIEW
// ============================================================

async getDeliveryKycSubmissions() {

  const { data: partners, error } = await supabase
    .from('delivery_partners')
    .select(`
      id,
      name,
      mobile,
      email,
      vehicle_type,
      vehicle_number,
      kyc_status,
      kyc_rejection_reason,
      created_at
    `)
    .eq('kyc_status', 'submitted')
    .order('created_at', { ascending: true });

  if (error) {
    throw new Error(error.message);
  }

  const submissions: any[] = [];

  for (const partner of partners ?? []) {
    const { data: documents } = await supabase
      .from('delivery_kyc_documents')
      .select(`
        document_type,
        storage_path,
        created_at
      `)
      .eq('delivery_partner_id', partner.id);

    const docs: any[] = [];

    for (const doc of documents ?? []) {
      const url = await this.storageService
        .getSignedDocumentUrl(doc.storage_path)
        .catch(() => null);

      docs.push({
        type: doc.document_type,
        uploadedAt: doc.created_at,
        url,
      });
    }

    submissions.push({
      ...partner,
      documents: docs,
    });
  }

  return {
    success: true,
    submissions,
  };
}

async approveDeliveryKyc(id: string) {

  const { data, error } = await supabase
    .from('delivery_partners')
    .update({
      kyc_status: 'verified',
      kyc_rejection_reason: null,
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {
    success: true,
    message: 'KYC verified',
    partner: data,
  };
}

async rejectDeliveryKyc(id: string, reason: string) {

  const { data, error } = await supabase
    .from('delivery_partners')
    .update({
      kyc_status: 'rejected',
      kyc_rejection_reason:
        reason || 'Documents were not clear enough',
    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {
    success: true,
    message: 'KYC rejected',
    partner: data,
  };
}
async blockDeliveryPartner(id: string) {

  const { data, error } = await supabase
    .from('delivery_partners')
    .update({

      is_online: false,

      is_available: false,

    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {

    success: true,

    message: 'Delivery partner blocked',

    partner: data,

  };

}
async unblockDeliveryPartner(id: string) {

  const { data, error } = await supabase
    .from('delivery_partners')
    .update({

      is_available: true,

    })
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {

    success: true,

    message: 'Delivery partner unblocked',

    partner: data,

  };

}
// ==========================
// Get All Orders (Admin)
// ==========================
async getOrders() {

  const { data: orders, error } = await supabase
    .from('orders')
    .select(`
      id,
      total_amount,
      payment_status,
      order_status,
      created_at,
      assigned_at,
      picked_up_at,
      out_for_delivery_at,
      delivered_at,

      customers (
        id,
        name,
        mobile,
        email
      ),

      restaurant_partners (
        id,
        restaurant_name,
        mobile,
        logo_url
      ),

      delivery_partners (
        id,
        name,
        mobile,
        vehicle_type,
        rating
      )
    `)
    .order('created_at', {
      ascending: false,
    });

  if (error) {
    throw new Error(error.message);
  }

  const formattedOrders =
    orders.map((order: any) => {

      const customer =
        Array.isArray(order.customers)
          ? order.customers[0]
          : order.customers;

      const restaurant =
        Array.isArray(order.restaurant_partners)
          ? order.restaurant_partners[0]
          : order.restaurant_partners;

      const rider =
        Array.isArray(order.delivery_partners)
          ? order.delivery_partners[0]
          : order.delivery_partners;

      return {

        id: order.id,

        orderNumber:
          `RB-${order.id.substring(0,8).toUpperCase()}`,

        totalAmount:
          order.total_amount,

        paymentStatus:
          order.payment_status,

        orderStatus:
          order.order_status,

        createdAt:
          order.created_at,

        customer: customer
          ? {
              id: customer.id,
              name: customer.name,
              mobile: customer.mobile,
              email: customer.email,
            }
          : null,

        restaurant: restaurant
          ? {
              id: restaurant.id,
              name: restaurant.restaurant_name,
              mobile: restaurant.mobile,
              logo: restaurant.logo_url,
            }
          : null,

        deliveryPartner: rider
          ? {
              id: rider.id,
              name: rider.name,
              mobile: rider.mobile,
              vehicleType: rider.vehicle_type,
              rating: rider.rating,
            }
          : null,

        timeline: {
          assignedAt: order.assigned_at,
          pickedUpAt: order.picked_up_at,
          outForDeliveryAt: order.out_for_delivery_at,
          deliveredAt: order.delivered_at,
        },

      };

    });

  return {

    success: true,

    totalOrders: formattedOrders.length,

    orders: formattedOrders,

  };

}
// ==========================
// Get Order Details
// ==========================
async getOrder(id: string) {

  const { data: order, error } =
    await supabase
      .from('orders')
      .select(`
        *,
        customers(*),
        restaurant_partners(*),
        delivery_partners(*),
        addresses(*),
        order_items(
          *,
          menu_items(*)
        )
      `)
      .eq('id', id)
      .single();

  if (error) {
    throw new Error(error.message);
  }

  const customer =
    Array.isArray(order.customers)
      ? order.customers[0]
      : order.customers;

  const restaurant =
    Array.isArray(order.restaurant_partners)
      ? order.restaurant_partners[0]
      : order.restaurant_partners;

  const rider =
    Array.isArray(order.delivery_partners)
      ? order.delivery_partners[0]
      : order.delivery_partners;

  const address =
    Array.isArray(order.addresses)
      ? order.addresses[0]
      : order.addresses;

  const items =
    order.order_items.map((item: any) => {

      const menu =
        Array.isArray(item.menu_items)
          ? item.menu_items[0]
          : item.menu_items;

      return {

        id: menu?.id,

        name: menu?.name,

        description: menu?.description,

        image: menu?.image_url,

        quantity: item.quantity,

        price: item.price,

        subtotal:
          item.quantity * item.price,

      };

    });

  return {

    success: true,

    order: {

      id: order.id,

      orderNumber:
        `RB-${order.id.substring(0,8).toUpperCase()}`,

      totalAmount:
        order.total_amount,

      paymentStatus:
        order.payment_status,

      orderStatus:
        order.order_status,

      createdAt:
        order.created_at,

      customer,

      restaurant,

      deliveryPartner: rider,

      deliveryAddress: address,

      items,

      timeline: {

        assignedAt:
          order.assigned_at,

        pickedUpAt:
          order.picked_up_at,

        outForDeliveryAt:
          order.out_for_delivery_at,

        deliveredAt:
          order.delivered_at,

      },

    },

  };

}
// ==========================
// Cancel Order
// ==========================
async cancelOrder(id: string) {
  // Admin cancellation is deliberately limited to orders that have not
  // entered restaurant preparation/dispatch. Paid orders must be refunded
  // through the provider-backed refund flow before they can be cancelled.
  const { data: currentOrder, error: lookupError } = await supabase
    .from('orders')
    .select('id, order_status, payment_status')
    .eq('id', id)
    .maybeSingle();

  if (lookupError) {
    throw new Error(lookupError.message);
  }

  if (!currentOrder) {
    throw new NotFoundException('Order not found');
  }

  if (!isAdminCancellableOrder(currentOrder.order_status, currentOrder.payment_status)) {
    throw new ConflictException(
      'Only pending orders with no outstanding payment can be cancelled. Refund paid orders first and do not cancel orders already accepted by the restaurant.',
    );
  }

  // Re-check both states in the UPDATE so a concurrent restaurant/payment
  // transition cannot be overwritten by this admin action.
  const { data, error } = await supabase
    .from('orders')
    .update({ order_status: 'cancelled' })
    .eq('id', id)
    .eq('order_status', 'pending')
    .in('payment_status', ['pending', 'failed', 'refunded'])
    .select()
    .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  if (!data) {
    throw new ConflictException(
      'Order state changed while cancellation was being processed. Refresh and review the order.',
    );
  }

  return {
    success: true,
    message: 'Order cancelled successfully',
    order: data,
  };
}
// ==========================
// Refund Order
// ==========================
async refundOrder(id: string) {
  // Use the same provider-backed refund flow as the payments endpoint.
  return this.paymentsService.refund(id);
}
async getAnalytics() {

  // Revenue & Orders
  const { data: orders } = await supabase
    .from('orders')
    .select('*');

  // Customers
  const { count: customers } = await supabase
    .from('customers')
    .select('*', { count: 'exact', head: true });

  // Restaurants
  const { count: restaurants } = await supabase
    .from('restaurant_partners')
    .select('*', { count: 'exact', head: true });

  // Delivery Partners
  const { data: riders } = await supabase
    .from('delivery_partners')
    .select('*');

  const totalRevenue =
    orders
      ?.filter(o => o.order_status === 'delivered')
      .reduce(
        (sum, o) =>
          sum + Number(o.total_amount),
        0,
      ) ?? 0;

  const today = new Date().toISOString().split('T')[0];

  const todayOrders =
    orders?.filter(o =>
      o.created_at.startsWith(today),
    ) ?? [];

  const todayRevenue =
    todayOrders
      .filter(o => o.order_status === 'delivered')
      .reduce(
        (sum, o) =>
          sum + Number(o.total_amount),
        0,
      );

      const restaurantMap = new Map();

orders?.forEach(order => {

  const id = order.restaurant_partner_id;

  if (!restaurantMap.has(id)) {

    restaurantMap.set(id, {
      restaurantPartnerId: id,
      orders: 0,
      revenue: 0,
    });

  }

  const restaurant = restaurantMap.get(id);

  restaurant.orders++;

  restaurant.revenue += Number(order.total_amount);

});

  return {

    success: true,

    overview: {

      totalRevenue,

      todayRevenue,

      totalOrders:
        orders?.length ?? 0,

      todayOrders:
        todayOrders.length,

      totalCustomers:
        customers,

      topRestaurants:
  Array.from(restaurantMap.values())
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 10),

      totalDeliveryPartners:
        riders?.length ?? 0,

      activeDeliveryPartners:
        riders?.filter(
          r => r.is_online,
        ).length ?? 0,

    },

    orders: {

      pending:
        orders?.filter(
          o => o.order_status === 'pending',
        ).length ?? 0,

      accepted:
        orders?.filter(
          o => o.order_status === 'accepted',
        ).length ?? 0,

      preparing:
        orders?.filter(
          o => o.order_status === 'preparing',
        ).length ?? 0,

      ready:
        orders?.filter(
          o => o.order_status === 'ready',
        ).length ?? 0,

      pickedUp:
        orders?.filter(
          o => o.order_status === 'picked_up',
        ).length ?? 0,

      outForDelivery:
        orders?.filter(
          o => o.order_status === 'out_for_delivery',
        ).length ?? 0,

      delivered:
        orders?.filter(
          o => o.order_status === 'delivered',
        ).length ?? 0,

      cancelled:
        orders?.filter(
          o => o.order_status === 'cancelled',
        ).length ?? 0,

    },

    recentOrders:
      orders
        ?.sort(
          (a, b) =>
            new Date(b.created_at).getTime() -
            new Date(a.created_at).getTime(),
        )
        .slice(0, 10),

  };

}
}

// Keep admin cancellation conservative: payment must be settled as unpaid,
// failed, or already refunded, and the restaurant must not have accepted it.
export function isAdminCancellableOrder(
  orderStatus: string,
  paymentStatus: string,
): boolean {
  return (
    orderStatus === 'pending' &&
    ['pending', 'failed', 'refunded'].includes(paymentStatus)
  );
}


export function isAllowedRestaurantAdminTransition(currentStatus: string, nextStatus: string): boolean {
  const transitions: Record<string, string[]> = {
    pending: ['approved', 'rejected'],
    approved: ['blocked'],
    blocked: ['approved'],
    rejected: [],
  };
  return transitions[currentStatus]?.includes(nextStatus) ?? false;
}
