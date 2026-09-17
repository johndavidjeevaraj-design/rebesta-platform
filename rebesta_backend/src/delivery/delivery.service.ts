import { Injectable, BadRequestException } from '@nestjs/common';

import { supabase } from '../supabase';
import { SocketGateway } from '../socket/socket.gateway';
import { MapsService } from '../maps/maps.service';
import { VerifyDeliveryOtpDto } from './dto/verify-delivery-otp.dto';

@Injectable()
export class DeliveryService {
  constructor(
    private readonly mapsService: MapsService,
    private readonly socketGateway: SocketGateway,
  ) {}

  // ============================================================
  // Available Orders
  // ============================================================

  async getAvailableOrders() {
    const { data, error } = await supabase
      .from('orders')
      .select(`
        id,
        total_amount,
        order_status,
        created_at,

        customers(
          name
        ),

        addresses(
          title,
          address,
          landmark,
          city,
          state,
          pincode,
          latitude,
          longitude
        )
      `)
      .eq('order_status', 'ready')
      .is('delivery_partner_id', null);

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      success: true,
      orders: data,
    };
  }

  // ============================================================
  // Dashboard
  // ============================================================

  async dashboard(deliveryPartnerId: string) {
    const { data: currentOrders, error: currentOrderError } =
      await supabase
        .from('orders')
        .select(`
          id,
          order_status,
          created_at,
          assigned_at,
          picked_up_at,
          out_for_delivery_at,
          delivered_at,
          otp_verified
        `)
        .eq('delivery_partner_id', deliveryPartnerId)
        .in('order_status', [
          'accepted_for_delivery',
          'arrived_at_restaurant',
          'picked_up',
          'out_for_delivery',
          'arrived_at_customer',
        ]);

    if (currentOrderError) {
      throw new BadRequestException(currentOrderError.message);
    }

    const { data: completedOrders, error: completedError } =
      await supabase
        .from('orders')
        .select(`
          id,
          order_status,
          created_at,
          delivered_at,
          otp_verified
        `)
        .eq('delivery_partner_id', deliveryPartnerId)
        .eq('order_status', 'delivered');

    if (completedError) {
      throw new BadRequestException(completedError.message);
    }

    return {
      success: true,

      dashboard: {
        currentOrders: currentOrders?.length ?? 0,
        completedDeliveries: completedOrders?.length ?? 0,
      },
    };
  }

  // ============================================================
  // Accept Order
  // ============================================================

  async acceptOrder(
    orderId: string,
    deliveryPartnerId: string,
  ) {
    const { data: order, error: findError } = await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        order_status,
        delivery_partner_id
      `)
      .eq('id', orderId)
      .single();

    if (findError || !order) {
      throw new BadRequestException('Order not found');
    }

    if (order.order_status !== 'ready') {
      throw new BadRequestException('Order is not ready');
    }

    if (order.delivery_partner_id) {
      throw new BadRequestException('Order already accepted');
    }

    const { data, error } = await supabase
      .from('orders')
      .update({
        delivery_partner_id: deliveryPartnerId,
        assigned_at: new Date().toISOString(),
        order_status: 'accepted_for_delivery',
      })
      .eq('id', orderId)
      .is('delivery_partner_id', null)
      .select()
      .single();

    if (error) {
      throw new BadRequestException(error.message);
    }

    if (!data) {
      throw new BadRequestException(
        'Order was accepted by another delivery partner',
      );
    }

    this.socketGateway.sendOrderUpdate(
      orderId,
      'accepted_for_delivery',
    );

    if (data.customer_id) {
      this.socketGateway.emitToCustomer(
        data.customer_id,
        'delivery_assigned',
        {
          orderId: data.id,
          status: data.order_status,
          deliveryPartnerId,
        },
      );
    }

    return {
      success: true,
      message: 'Order accepted successfully',
      order: data,
    };
  }

  // ============================================================
  // Reached Pickup Location
  // ============================================================

  async arriveAtRestaurant(
    orderId: string,
    deliveryPartnerId: string,
  ) {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`id, customer_id, order_status, delivery_partner_id`)
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (order.order_status !== 'accepted_for_delivery') {
      throw new BadRequestException('Order is not accepted for delivery');
    }

    const { data, error: updateError } = await supabase
      .from('orders')
      .update({
        order_status: 'arrived_at_restaurant',
      })
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .select()
      .single();

    if (updateError) {
      throw new BadRequestException(updateError.message);
    }

    this.socketGateway.sendOrderUpdate(orderId, 'arrived_at_restaurant');

    if (data.customer_id) {
      this.socketGateway.emitToCustomer(
        data.customer_id,
        'order_status',
        { orderId: data.id, status: data.order_status },
      );
    }

    return {
      success: true,
      message: 'Marked as reached pickup location',
      order: data,
    };
  }

  // ============================================================
  // Reached Customer Location
  // ============================================================

  async arriveAtCustomer(
    orderId: string,
    deliveryPartnerId: string,
  ) {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        order_status,
        delivery_partner_id
      `)
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (order.order_status !== 'out_for_delivery') {
      throw new BadRequestException(
        `Order is not out for delivery. Current status: ${order.order_status}`,
      );
    }

    const { data, error: updateError } = await supabase
      .from('orders')
      .update({
        order_status: 'arrived_at_customer',
      })
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .eq('order_status', 'out_for_delivery')
      .select()
      .single();

    if (updateError) {
      throw new BadRequestException(updateError.message);
    }

    if (!data) {
      throw new BadRequestException(
        'Order could not be marked as arrived at customer',
      );
    }

    this.socketGateway.sendOrderUpdate(
      orderId,
      'arrived_at_customer',
    );

    if (data.customer_id) {
      this.socketGateway.emitToCustomer(
        data.customer_id,
        'order_status',
        {
          orderId: data.id,
          status: data.order_status,
        },
      );
    }

    return {
      success: true,
      message: 'Marked as reached customer location',
      order: data,
    };
  }

  // ============================================================
  // Cancel (unassign) — puts order back to "ready" for another rider
  // ============================================================

  async cancelDelivery(
    orderId: string,
    deliveryPartnerId: string,
  ) {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`id, order_status, delivery_partner_id`)
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (
      order.order_status === 'delivered' ||
      order.order_status === 'picked_up' ||
      order.order_status === 'arrived_at_customer'
    ) {
      throw new BadRequestException('Order cannot be cancelled at this stage');
    }

    const { data, error: updateError } = await supabase
      .from('orders')
      .update({
        order_status: 'ready',
        delivery_partner_id: null,
        assigned_at: null,
      })
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .select()
      .single();

    if (updateError) {
      throw new BadRequestException(updateError.message);
    }

    this.socketGateway.sendOrderUpdate(orderId, 'ready');

    return {
      success: true,
      message: 'Delivery cancelled, order returned to pool',
      order: data,
    };
  }

  // ============================================================
  // Complete Delivery WITHOUT OTP (experienced riders, 50+ deliveries)
  // ============================================================

  async completeDeliveryWithoutOtp(
    orderId: string,
    deliveryPartnerId: string,
  ) {
    const { data: partner, error: partnerError } = await supabase
      .from('delivery_partners')
      .select('completed_deliveries')
      .eq('id', deliveryPartnerId)
      .single();

    if (partnerError || !partner) {
      throw new BadRequestException('Delivery partner not found');
    }

    if (Number(partner.completed_deliveries ?? 0) < 50) {
      throw new BadRequestException(
        'OTP verification is required for this delivery',
      );
    }

    const { data: order, error } = await supabase
      .from('orders')
      .select(`id, customer_id, order_status, delivery_partner_id`)
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (order.order_status !== 'arrived_at_customer') {
      throw new BadRequestException(
        'Rider has not reached the customer location yet',
      );
    }

    const { data: updatedOrder, error: updateError } = await supabase
      .from('orders')
      .update({
        order_status: 'delivered',
        delivered_at: new Date().toISOString(),
        otp_verified: false,
      })
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .eq('order_status', 'arrived_at_customer')
      .select()
      .single();

    if (updateError) {
      throw new BadRequestException(updateError.message);
    }

    if (!updatedOrder) {
      throw new BadRequestException('Delivery could not be completed');
    }

    const earningAmount = 40;

    const { data: existingEarning, error: earningCheckError } =
      await supabase
        .from('delivery_earnings')
        .select('id, amount, status')
        .eq('order_id', orderId)
        .maybeSingle();

    if (earningCheckError) {
      throw new BadRequestException(
        `Unable to check delivery earning: ${earningCheckError.message}`,
      );
    }

    if (!existingEarning) {
      const { error: earningInsertError } = await supabase
        .from('delivery_earnings')
        .insert({
          delivery_partner_id: deliveryPartnerId,
          order_id: orderId,
          amount: earningAmount,
          status: 'pending',
        });

      if (earningInsertError) {
        throw new BadRequestException(
          `Delivery completed, but earning creation failed: ${earningInsertError.message}`,
        );
      }

      const { data: partnerWallet, error: partnerWalletError } =
        await supabase
          .from('delivery_partners')
          .select(
            `wallet_balance, total_earnings, pending_payout, completed_deliveries`,
          )
          .eq('id', deliveryPartnerId)
          .single();

      if (partnerWalletError || !partnerWallet) {
        throw new BadRequestException(
          'Delivery completed, but delivery partner wallet was not found',
        );
      }

      const { error: walletError } = await supabase
        .from('delivery_partners')
        .update({
          wallet_balance:
            Number(partnerWallet.wallet_balance ?? 0) + earningAmount,
          total_earnings:
            Number(partnerWallet.total_earnings ?? 0) + earningAmount,
          pending_payout:
            Number(partnerWallet.pending_payout ?? 0) + earningAmount,
          completed_deliveries:
            Number(partnerWallet.completed_deliveries ?? 0) + 1,
        })
        .eq('id', deliveryPartnerId);

      if (walletError) {
        throw new BadRequestException(
          `Delivery completed, but wallet update failed: ${walletError.message}`,
        );
      }
    }

    this.socketGateway.sendOrderUpdate(orderId, 'delivered');

    if (updatedOrder.customer_id) {
      this.socketGateway.emitToCustomer(
        updatedOrder.customer_id,
        'order_status',
        { orderId: updatedOrder.id, status: 'delivered' },
      );
    }

    return {
      success: true,
      message: 'Delivery completed successfully',
      order: updatedOrder,
      earning: {
        amount: earningAmount,
        status: existingEarning ? 'already_recorded' : 'pending',
      },
    };
  }

  // ============================================================
  // Pick Up Order
  // ============================================================

  async pickUpOrder(
    orderId: string,
    deliveryPartnerId: string,
  ) {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        order_status,
        delivery_partner_id
      `)
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (order.order_status !== 'arrived_at_restaurant') {
      throw new BadRequestException(
        `Order cannot be picked up. Current status: ${order.order_status}`,
      );
    }

    const { data, error: updateError } = await supabase
      .from('orders')
      .update({
        order_status: 'picked_up',
        picked_up_at: new Date().toISOString(),
      })
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .eq('order_status', 'arrived_at_restaurant')
      .select()
      .single();

    if (updateError) {
      throw new BadRequestException(updateError.message);
    }

    this.socketGateway.sendOrderUpdate(
      orderId,
      'picked_up',
    );

    if (data.customer_id) {
      this.socketGateway.emitToCustomer(
        data.customer_id,
        'order_status',
        {
          orderId: data.id,
          status: data.order_status,
        },
      );
    }

    return {
      success: true,
      message: 'Order picked up',
      order: data,
    };
  }

  // ============================================================
  // Out For Delivery
  // ============================================================

  async outForDelivery(
    orderId: string,
    deliveryPartnerId: string,
  ) {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        order_status,
        delivery_partner_id
      `)
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (order.order_status !== 'picked_up') {
      throw new BadRequestException('Order is not picked up');
    }

    const { data, error: updateError } = await supabase
      .from('orders')
      .update({
        order_status: 'out_for_delivery',
        out_for_delivery_at: new Date().toISOString(),
      })
      .eq('id', orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .select()
      .single();

    if (updateError) {
      throw new BadRequestException(updateError.message);
    }

    this.socketGateway.sendOrderUpdate(
      orderId,
      'out_for_delivery',
    );

    if (data.customer_id) {
      this.socketGateway.emitToCustomer(
        data.customer_id,
        'order_status',
        {
          orderId: data.id,
          status: data.order_status,
        },
      );
    }

    return {
      success: true,
      message: 'Order is out for delivery',
      order: data,
    };
  }

  // ============================================================
  // Verify Delivery OTP
  // ============================================================

  async verifyOtp(
    deliveryPartnerId: string,
    dto: VerifyDeliveryOtpDto,
  ) {
    const { data: order, error } = await supabase
      .from('orders')
      .select(`
        id,
        customer_id,
        order_status,
        delivery_partner_id,
        delivery_otp,
        otp_verified,
        delivered_at
      `)
      .eq('id', dto.orderId)
      .eq('delivery_partner_id', deliveryPartnerId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (
      order.order_status === 'delivered' &&
      order.otp_verified === true
    ) {
      return {
        success: true,
        message: 'Delivery already completed',
        order,
        earning: {
          amount: 40,
          status: 'already_recorded',
        },
      };
    }

    if (order.order_status !== 'arrived_at_customer') {
      throw new BadRequestException(
        `Order is not ready for OTP verification. Current status: ${order.order_status}`,
      );
    }

    if (order.otp_verified) {
      throw new BadRequestException('OTP already verified');
    }

    if (
      String(order.delivery_otp) !==
      String(dto.otp)
    ) {
      throw new BadRequestException('Invalid OTP');
    }

    const { data: updatedOrder, error: updateError } =
      await supabase
        .from('orders')
        .update({
          otp_verified: true,
          order_status: 'delivered',
          delivered_at: new Date().toISOString(),
        })
        .eq('id', dto.orderId)
        .eq('delivery_partner_id', deliveryPartnerId)
        .eq('order_status', 'arrived_at_customer')
        .eq('otp_verified', false)
        .select()
        .single();

    if (updateError) {
      throw new BadRequestException(updateError.message);
    }

    if (!updatedOrder) {
      throw new BadRequestException('Delivery could not be completed');
    }

    const earningAmount = 40;

    const {
      data: existingEarning,
      error: earningCheckError,
    } = await supabase
      .from('delivery_earnings')
      .select('id, amount, status')
      .eq('order_id', dto.orderId)
      .maybeSingle();

    if (earningCheckError) {
      throw new BadRequestException(
        `Unable to check delivery earning: ${earningCheckError.message}`,
      );
    }

    if (!existingEarning) {
      const { error: earningInsertError } =
        await supabase
          .from('delivery_earnings')
          .insert({
            delivery_partner_id: deliveryPartnerId,
            order_id: dto.orderId,
            amount: earningAmount,
            status: 'pending',
          });

      if (earningInsertError) {
        throw new BadRequestException(
          `Delivery completed, but earning creation failed: ${earningInsertError.message}`,
        );
      }
    }

    const {
      data: partner,
      error: partnerError,
    } = await supabase
      .from('delivery_partners')
      .select(`
        wallet_balance,
        total_earnings,
        pending_payout,
        completed_deliveries
      `)
      .eq('id', deliveryPartnerId)
      .single();

    if (partnerError || !partner) {
      throw new BadRequestException(
        'Delivery completed, but delivery partner wallet was not found',
      );
    }

    if (!existingEarning) {
      const { error: walletError } =
        await supabase
          .from('delivery_partners')
          .update({
            wallet_balance:
              Number(partner.wallet_balance ?? 0) +
              earningAmount,

            total_earnings:
              Number(partner.total_earnings ?? 0) +
              earningAmount,

            pending_payout:
              Number(partner.pending_payout ?? 0) +
              earningAmount,

            completed_deliveries:
              Number(partner.completed_deliveries ?? 0) +
              1,
          })
          .eq('id', deliveryPartnerId);

      if (walletError) {
        throw new BadRequestException(
          `Delivery completed, but wallet update failed: ${walletError.message}`,
        );
      }
    }

    this.socketGateway.sendOrderUpdate(
      dto.orderId,
      'delivered',
    );

    if (updatedOrder.customer_id) {
      this.socketGateway.emitToCustomer(
        updatedOrder.customer_id,
        'order_status',
        {
          orderId: updatedOrder.id,
          status: 'delivered',
        },
      );
    }

    return {
      success: true,
      message: 'Delivery completed successfully',
      order: updatedOrder,
      earning: {
        amount: earningAmount,
        status: existingEarning
          ? 'already_recorded'
          : 'pending',
      },
    };
  }

  // ============================================================
  // Online / Offline Status
  // ============================================================

  async updateStatus(
    deliveryPartnerId: string,
    isOnline: boolean,
  ) {
    const { data, error } = await supabase
      .from('delivery_partners')
      .update({
        is_online: isOnline,
        is_available: isOnline,
      })
      .eq('id', deliveryPartnerId)
      .select()
      .single();

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      success: true,

      message: isOnline
        ? 'You are now online'
        : 'You are now offline',

      partner: data,
    };
  }

  // ============================================================
  // Delivery History
  // ============================================================

  async getMyDeliveries(
    deliveryPartnerId: string,
  ) {
    const { data, error } = await supabase
      .from('orders')
      .select(`
        id,
        total_amount,
        order_status,
        delivered_at,

        customers(
          name
        ),

        restaurant_partners(
          restaurant_name
        )
      `)
      .eq(
        'delivery_partner_id',
        deliveryPartnerId,
      )
      .order(
        'created_at',
        {
          ascending: false,
        },
      );

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      success: true,
      deliveries: data,
    };
  }

  // ============================================================
  // Update Delivery Partner Location
  // ============================================================

  async updateLocation(
    deliveryPartnerId: string,
    latitude: number,
    longitude: number,
  ) {
    const { error } = await supabase
      .from('delivery_partners')
      .update({
        current_latitude: latitude,
        current_longitude: longitude,
        last_location_updated_at: new Date().toISOString(),
      })
      .eq('id', deliveryPartnerId);

    if (error) {
      throw new BadRequestException(error.message);
    }

    const { data: orders, error: ordersError } =
      await supabase
        .from('orders')
        .select(`
          id,
          customer_id,
          order_status
        `)
        .eq(
          'delivery_partner_id',
          deliveryPartnerId,
        )
        .in(
          'order_status',
          [
            'accepted_for_delivery',
            'arrived_at_restaurant',
            'picked_up',
            'out_for_delivery',
            'arrived_at_customer',
          ],
        );

    if (ordersError) {
      throw new BadRequestException(
        `Unable to find active delivery orders: ${ordersError.message}`,
      );
    }

    for (const order of orders ?? []) {
      if (!order.customer_id) {
        continue;
      }

      this.socketGateway.emitToCustomer(
        order.customer_id,
        'delivery_location',
        {
          orderId: order.id,
          deliveryPartnerId,
          latitude,
          longitude,
        },
      );
    }

    return {
      success: true,
      latitude,
      longitude,
      activeOrders: orders?.length ?? 0,
    };
  }

  // ============================================================
  // Wallet
  // ============================================================

  async wallet(
    deliveryPartnerId: string,
  ) {
    const { data, error } = await supabase
      .from('delivery_partners')
      .select(`
        wallet_balance,
        pending_payout,
        total_earnings,
        completed_deliveries
      `)
      .eq('id', deliveryPartnerId)
      .single();

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      success: true,
      wallet: data,
    };
  }

  // ============================================================
  // Earnings History
  // ============================================================

  async earnings(
    deliveryPartnerId: string,
  ) {
    const { data, error } = await supabase
      .from('delivery_earnings')
      .select('*')
      .eq(
        'delivery_partner_id',
        deliveryPartnerId,
      )
      .order(
        'created_at',
        {
          ascending: false,
        },
      );

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      success: true,
      earnings: data,
    };
  }

  // ============================================================
  // Active Orders
  // ============================================================

  async getActiveOrders(
    deliveryPartnerId: string,
  ) {
    const { data, error } =
      await supabase
        .from('orders')
        .select(`
          id,
          customer_id,
          total_amount,
          order_status,
          created_at,
          assigned_at,
          picked_up_at,
          out_for_delivery_at,
          delivered_at,
          otp_verified,

          customers(
            name
          ),

          addresses(
            title,
            address,
            landmark,
            city,
            state,
            pincode,
            latitude,
            longitude
          ),

          restaurant_partners(
            restaurant_name
          )
        `)
        .eq(
          'delivery_partner_id',
          deliveryPartnerId,
        )
        .in(
          'order_status',
          [
            'accepted_for_delivery',
            'arrived_at_restaurant',
            'picked_up',
            'out_for_delivery',
            'arrived_at_customer',
          ],
        )
        .order(
          'created_at',
          { ascending: false },
        );

    if (error) {
      throw new BadRequestException(error.message);
    }

    return {
      success: true,
      orders: data ?? [],
    };
  }
}