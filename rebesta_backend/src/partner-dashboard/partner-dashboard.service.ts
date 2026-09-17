import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';

@Injectable()
export class PartnerDashboardService {

  async getDashboard(
    restaurantPartnerId: string,
  ) {

    // All restaurant orders

    const { data: orders, error } =
      await supabase
        .from('orders')
        .select(`
          id,
          total_amount,
          order_status,
          created_at
        `)
        .eq(
          'restaurant_partner_id',
          restaurantPartnerId,
        );

    if (error) {
      throw new Error(error.message);
    }

    const today = new Date().toISOString().split('T')[0];

    const todayOrders = orders.filter(
      (o) =>
        o.created_at.startsWith(today),
    );

    const dashboard = {

      todayOrders:
        todayOrders.length,

      todayRevenue:
        todayOrders.reduce(
          (sum, o) =>
            sum + Number(o.total_amount),
          0,
        ),

      pendingOrders:
        orders.filter(
          (o) =>
            o.order_status === 'pending',
        ).length,

      acceptedOrders:
        orders.filter(
          (o) =>
            o.order_status === 'accepted',
        ).length,

      preparingOrders:
        orders.filter(
          (o) =>
            o.order_status === 'preparing',
        ).length,

      readyOrders:
        orders.filter(
          (o) =>
            o.order_status === 'ready',
        ).length,

      completedOrders:
        orders.filter(
          (o) =>
            o.order_status === 'completed',
        ).length,

      totalOrders:
        orders.length,

      totalRevenue:
        orders.reduce(
          (sum, o) =>
            sum + Number(o.total_amount),
          0,
        ),

    };

    return {

      success: true,

      dashboard,

    };

  }

}