import {
  Injectable,
  BadRequestException,
} from '@nestjs/common';

import axios from 'axios';
import * as crypto from 'crypto';

import { supabase } from '../supabase';
import { SocketGateway } from '../socket/socket.gateway';
import { FcmService } from '../fcm/fcm.service';
import { MapsService } from '../maps/maps.service';

import { CouponsService } from '../coupons/coupons.service';
import { CreateCheckoutPaymentDto } from './dto/create-checkout-payment.dto';
import { VerifyPaymentDto } from './dto/verify-payment.dto';

@Injectable()
export class PaymentsService {

  constructor(
    private readonly socketGateway: SocketGateway,
    private readonly fcmService: FcmService,
    private readonly mapsService: MapsService,
    private readonly couponsService: CouponsService,
  ) {}

  // ============================================================
  // CREATE CHECKOUT PAYMENT
  //
  // Validates cart, calculates price server-side, creates a
  // Cashfree order, and stores a payment_attempts row.
  //
  // IMPORTANT: this does NOT create a row in `orders`. No real
  // order exists until payment is verified.
  // ============================================================

  async createCheckoutPayment(
    customerId: string,
    dto: CreateCheckoutPaymentDto,
  ) {
    // ----------------------------------------------------------
    // GET CART
    // ----------------------------------------------------------

    const { data: cart, error: cartError } = await supabase
      .from('carts')
      .select(`
        id,
        cart_items(
          id,
          menu_item_id,
          quantity
        )
      `)
      .eq('customer_id', customerId)
      .eq('restaurant_partner_id', dto.restaurantPartnerId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (cartError) {
      throw new BadRequestException(
        `Cart lookup failed: ${cartError.message}`,
      );
    }

    if (!cart) {
      throw new BadRequestException('Cart not found');
    }

    const cartItems = Array.isArray(cart.cart_items)
      ? cart.cart_items
      : [];

    if (cartItems.length === 0) {
      throw new BadRequestException('Cart is empty');
    }

    // ----------------------------------------------------------
    // RE-VALIDATE PRICES AGAINST LIVE MENU DATA
    //
    // Never trust stored cart price — always price from the
    // current menu_items row, so a client can never manipulate
    // the amount charged.
    // ----------------------------------------------------------

    const snapshot: Array<{
      cartItemId: string;
      menuItemId: string;
      quantity: number;
      price: number;
    }> = [];

    let subtotal = 0;

    for (const item of cartItems) {
      const { data: menuItem, error: menuError } = await supabase
        .from('menu_items')
        .select('id, price, is_available, restaurant_partner_id')
        .eq('id', item.menu_item_id)
        .single();

      if (menuError || !menuItem) {
        throw new BadRequestException(
          'One or more items in your cart are no longer available',
        );
      }

      if (!menuItem.is_available) {
        throw new BadRequestException(
          'One or more items in your cart are currently unavailable',
        );
      }

      if (menuItem.restaurant_partner_id !== dto.restaurantPartnerId) {
        throw new BadRequestException('Cart contains an item from another restaurant');
      }

      const quantity = Number(item.quantity ?? 0);
      const price = Number(menuItem.price ?? 0);

      if (!Number.isSafeInteger(quantity) || quantity <= 0) {
        throw new BadRequestException('Invalid cart quantity');
      }
      if (!Number.isFinite(price) || price < 0) {
        throw new BadRequestException('Invalid menu price');
      }

      snapshot.push({
        cartItemId: item.id,
        menuItemId: menuItem.id,
        quantity,
        price,
      });

      subtotal += price * quantity;
    }

    // ----------------------------------------------------------
    // VALIDATE ADDRESS
    // ----------------------------------------------------------

    // ----------------------------------------------------------
// VALIDATE ADDRESS (delivery only — pickup has none)
// ----------------------------------------------------------

const isPickup = dto.orderType === 'pickup';

let address: any = null;

if (!isPickup) {
  if (!dto.addressId) throw new Error('Delivery address required');

  const { data, error: addressError } = await supabase
    .from('addresses')
    .select('id, latitude, longitude')
    .eq('id', dto.addressId)
    .eq('user_id', customerId)
    .single();

  if (addressError || !data) throw new Error('Invalid delivery address');
  address = data;
}

// ==========================================================
// DELIVERY FEE — shared engine
// ==========================================================

let deliveryFee = 0;

if (!isPickup) {
  const { data: restaurant, error: restaurantError } =
    await supabase
      .from('restaurants')
      .select('latitude, longitude')
      .eq(
        'restaurant_partner_id',
        dto.restaurantPartnerId,
      )
      .maybeSingle();

  if (restaurantError) {
    throw new BadRequestException(
      `Restaurant lookup failed: ${restaurantError.message}`,
    );
  }

  if (
    restaurant?.latitude == null ||
    restaurant?.longitude == null
  ) {
    throw new BadRequestException(
      'Restaurant location is unavailable',
    );
  }

  const feeEstimate =
    await this.mapsService.calculateOrderDeliveryFee({
      restaurantLat: Number(restaurant.latitude),
      restaurantLng: Number(restaurant.longitude),

      addressLat: Number(address.latitude),
      addressLng: Number(address.longitude),

      subtotal,

      orderType: 'delivery',
    });

  deliveryFee = Number(feeEstimate.fee ?? 0);
}
    // Note: MapsService straight-line/ETA logic can be reused
    // here identically to orders.service.ts's old checkout() —
    // omitted for brevity, inject MapsService the same way and
    // call it exactly as before.
// ----------------------------------------------------------
// RESTAURANT OFFER
// ----------------------------------------------------------
//
// The customer only sends the offer code.
// The backend validates the offer and calculates the
// discount. Never trust a discount amount from Flutter.
//

let discount = 0;
let finalDeliveryFee = deliveryFee;
let appliedCoupon: any = null;

if (dto.couponCode) {
  const offerResult =
    await this.couponsService.applyCoupon(
      customerId,
      dto.couponCode,
      subtotal,
      dto.restaurantPartnerId,
      deliveryFee,
    );

  discount = Number(
    offerResult.discount ?? 0,
  );

  finalDeliveryFee = Number(
    offerResult.finalDeliveryFee ??
      deliveryFee,
  );

  appliedCoupon = offerResult.coupon;
}

const totalAmount = Number((
  subtotal +
  finalDeliveryFee -
  discount
).toFixed(2));

if (!Number.isFinite(totalAmount) || totalAmount <= 0 || !Number.isSafeInteger(Math.round(totalAmount * 100))) {
  throw new BadRequestException(
    'Invalid order amount',
  );
}
    // Create a local attempt first so retries use a stable Cashfree order ID
    // and idempotency key. The client never supplies amount or credentials.
    const { data: customer, error: customerError } = await supabase
      .from('customers')
      .select('id, name, mobile, email')
      .eq('id', customerId)
      .maybeSingle();

    if (customerError || !customer?.mobile) {
      throw new BadRequestException('A verified customer phone number is required for online payment');
    }
    let customerPhone = String(customer.mobile).replace(/\D/g, '');
    if (customerPhone.length === 12 && customerPhone.startsWith('91')) {
      customerPhone = customerPhone.slice(2);
    }
    if (!/^\d{10}$/.test(customerPhone)) {
      throw new BadRequestException('A valid 10-digit customer phone number is required for Cashfree payment');
    }

    const cashfreeOrderId = `rb_${crypto.randomUUID().replace(/-/g, '')}`;
    const { data: attempt, error: insertError } = await supabase
      .from('payment_attempts')
      .insert({
        customer_id: customerId,
        restaurant_partner_id: dto.restaurantPartnerId,
        address_id: isPickup ? null : dto.addressId,
        order_type: isPickup ? 'pickup' : 'delivery',
        subtotal,
        discount_amount: discount,
        delivery_fee: finalDeliveryFee,
        total_amount: totalAmount,
        coupon_code: dto.couponCode ?? null,
        cart_items_snapshot: snapshot,
        payment_provider: 'cashfree',
        cashfree_order_id: cashfreeOrderId,
        status: 'created',
      })
      .select('id, cashfree_idempotency_key')
      .single();

    if (insertError || !attempt) {
      throw new BadRequestException(insertError?.message ?? 'Could not create payment attempt');
    }

    try {
      const orderPayload: Record<string, any> = {
        order_id: cashfreeOrderId,
        order_amount: Number(totalAmount.toFixed(2)),
        order_currency: 'INR',
        customer_details: {
          customer_id: customerId,
          ...(customer.name ? { customer_name: customer.name } : {}),
          ...(customer.email ? { customer_email: customer.email } : {}),
          customer_phone: customerPhone,
        },
        order_note: isPickup ? 'Food pickup order' : 'Food delivery order',
      };

      const orderMeta: Record<string, string> = {};
      if (process.env.CASHFREE_RETURN_URL) {
        orderMeta.return_url = `${process.env.CASHFREE_RETURN_URL}${process.env.CASHFREE_RETURN_URL.includes('?') ? '&' : '?'}order_id={order_id}`;
      }
      if (process.env.CASHFREE_NOTIFY_URL) {
        orderMeta.notify_url = process.env.CASHFREE_NOTIFY_URL;
      }
      if (Object.keys(orderMeta).length > 0) {
        orderPayload.order_meta = orderMeta;
      }

      const response = await axios.post(
        `${this.cashfreeBaseUrl()}/orders`,
        orderPayload,
        {
          headers: this.cashfreeHeaders(String(attempt.cashfree_idempotency_key)),
          timeout: 15000,
        },
      );

      const cashfreeOrder = response.data;
      if (!cashfreeOrder?.payment_session_id || cashfreeOrder.order_id !== cashfreeOrderId) {
        throw new Error('Cashfree returned an invalid order session');
      }

      const { error: sessionError } = await supabase
        .from('payment_attempts')
        .update({ cashfree_payment_session_id: cashfreeOrder.payment_session_id })
        .eq('id', attempt.id)
        .eq('payment_provider', 'cashfree');

      if (sessionError) {
        throw new Error('Cashfree order created but payment session could not be saved; reconcile before retrying');
      }

      return {
        success: true,
        provider: 'cashfree',
        orderId: cashfreeOrderId,
        paymentSessionId: cashfreeOrder.payment_session_id,
        environment: this.cashfreeEnvironment(),
        amount: Number(cashfreeOrder.order_amount ?? totalAmount),
        currency: cashfreeOrder.order_currency ?? 'INR',
        subtotal,
        discount,
        deliveryFee: finalDeliveryFee,
        totalAmount,
        coupon: appliedCoupon
          ? {
              id: appliedCoupon.id,
              code: appliedCoupon.code,
              title: appliedCoupon.title,
              description: appliedCoupon.description,
              freeDelivery: appliedCoupon.free_delivery === true,
            }
          : null,
      };
    } catch (providerError: any) {
      await supabase
        .from('payment_attempts')
        .update({ status: 'failed' })
        .eq('id', attempt.id)
        .eq('status', 'created');
      const providerMessage = providerError?.response?.data?.message;
      throw new BadRequestException(
        typeof providerMessage === 'string'
          ? `Cashfree order creation failed: ${providerMessage}`
          : 'Cashfree order creation failed. Please try again.',
      );
    }
  }

  // ============================================================
  // VERIFY PAYMENT → CREATE THE REAL ORDER
  //
  // This is the ONLY place a real `orders` row gets created
  // for a customer checkout. It is idempotent: if this payment
  // attempt was already converted into an order, the existing
  // order is returned instead of creating a duplicate.
  // ============================================================
  // ============================================================
  // VERIFY PAYMENT (client-triggered path)
  // ============================================================

  private assertCashfreePaymentMatchesAttempt(payment: any, attempt: any) {
    if (!isCashfreePaymentMatch(payment, attempt)) {
      throw new BadRequestException('Cashfree payment does not match the expected order, amount and currency');
    }
  }

  private async getSuccessfulCashfreePayment(orderId: string, attempt: any) {
    const response = await axios.get(
      `${this.cashfreeBaseUrl()}/orders/${encodeURIComponent(orderId)}/payments`,
      { headers: this.cashfreeHeaders(), timeout: 15000 },
    );
    const payments = Array.isArray(response.data) ? response.data : [];
    const successful = payments.find((payment: any) => payment.payment_status === 'SUCCESS');
    if (!successful) return null;
    this.assertCashfreePaymentMatchesAttempt(successful, attempt);
    return successful;
  }

  async verifyPayment(customerId: string, dto: VerifyPaymentDto) {
    const { data: attempt, error } = await supabase
      .from('payment_attempts')
      .select('*')
      .eq('cashfree_order_id', dto.cashfreeOrderId)
      .eq('customer_id', customerId)
      .eq('payment_provider', 'cashfree')
      .maybeSingle();

    if (error || !attempt) throw new BadRequestException('Cashfree payment attempt not found');

    if (attempt.order_id) {
      const { data: existingOrder } = await supabase
        .from('orders')
        .select('id, order_status, payment_status, total_amount')
        .eq('id', attempt.order_id)
        .maybeSingle();
      return { success: true, message: 'Payment already verified', order: existingOrder };
    }

    const payment = await this.getSuccessfulCashfreePayment(dto.cashfreeOrderId, attempt);
    if (!payment) {
      throw new BadRequestException('Cashfree has not confirmed a successful payment yet');
    }
    return this.createOrderFromCashfreeAttempt(attempt, String(payment.cf_payment_id));
  }

  async reconcilePayment(customerId: string, cashfreeOrderId: string) {
    const { data: attempt, error } = await supabase
      .from('payment_attempts')
      .select('*')
      .eq('cashfree_order_id', cashfreeOrderId)
      .eq('customer_id', customerId)
      .eq('payment_provider', 'cashfree')
      .maybeSingle();

    if (error || !attempt) throw new BadRequestException('Cashfree payment attempt not found');

    if (attempt.order_id) {
      const { data: existingOrder } = await supabase
        .from('orders')
        .select('id, order_status, payment_status, total_amount')
        .eq('id', attempt.order_id)
        .maybeSingle();
      return { success: true, state: 'confirmed', order: existingOrder };
    }

    const [orderResponse, paymentListResponse] = await Promise.all([
      axios.get(
        `${this.cashfreeBaseUrl()}/orders/${encodeURIComponent(cashfreeOrderId)}`,
        { headers: this.cashfreeHeaders(), timeout: 15000 },
      ),
      axios.get(
        `${this.cashfreeBaseUrl()}/orders/${encodeURIComponent(cashfreeOrderId)}/payments`,
        { headers: this.cashfreeHeaders(), timeout: 15000 },
      ),
    ]);
    const providerOrderStatus = orderResponse.data?.order_status;
    const payments = Array.isArray(paymentListResponse.data) ? paymentListResponse.data : [];
    const successfulPayment = payments.find((item: any) => item.payment_status === 'SUCCESS');
    if (successfulPayment) {
      this.assertCashfreePaymentMatchesAttempt(successfulPayment, attempt);
      const result = await this.createOrderFromCashfreeAttempt(
        attempt,
        String(successfulPayment.cf_payment_id),
      );
      return { success: true, state: 'confirmed', order: result.order };
    }
    const terminalFailureStatuses = ['FAILED', 'USER_DROPPED', 'CANCELLED', 'VOID'];
    const allAttemptsFailed = payments.length > 0 &&
      payments.every((item: any) => terminalFailureStatuses.includes(String(item.payment_status).toUpperCase()));

    if (providerOrderStatus === 'EXPIRED' || allAttemptsFailed) {
      await supabase.from('payment_attempts')
        .update({ status: 'failed' })
        .eq('id', attempt.id)
        .eq('status', 'created');
      return { success: true, state: 'failed', order: null };
    }

    return { success: true, state: 'pending', order: null };
  }

  // Cashfree refund requests are idempotent: the refund ID is persisted
  // before the provider call and reused if the outcome is uncertain.
  async refund(orderId: string) {
    const { data: order, error } = await supabase
      .from('orders')
      .select('id, payment_status, total_amount, razorpay_order_id, cashfree_order_id, cashfree_payment_id, cashfree_refund_id')
      .eq('id', orderId)
      .maybeSingle();

    if (error || !order) throw new BadRequestException('Order not found');
    if (order.payment_status === 'refunded') {
      return { success: true, message: 'Order has already been refunded' };
    }
    if (!order.cashfree_order_id || !order.cashfree_payment_id) {
      if (order.razorpay_order_id) {
        throw new BadRequestException('This is a historical Razorpay payment. Refund it through the original Razorpay dashboard; Cashfree cannot refund it.');
      }
      throw new BadRequestException('This order does not have a Cashfree payment');
    }

    let refundId = order.cashfree_refund_id;
    if (order.payment_status === 'paid') {
      refundId = `rf_${crypto.randomUUID().replace(/-/g, '')}`;
      const { data: claimed, error: claimError } = await supabase
        .from('orders')
        .update({
          payment_status: 'refund_pending',
          cashfree_refund_id: refundId,
          cashfree_refund_status: 'PENDING',
        })
        .eq('id', orderId)
        .eq('payment_status', 'paid')
        .select('id')
        .maybeSingle();
      if (claimError || !claimed) {
        throw new BadRequestException('Refund is already being processed or order state changed');
      }
    } else if (order.payment_status !== 'refund_pending' || !refundId) {
      throw new BadRequestException('Only paid orders can be refunded');
    }

    try {
      let providerRefund: any;
      try {
        const fetched = await axios.get(
          `${this.cashfreeBaseUrl()}/orders/${encodeURIComponent(order.cashfree_order_id)}/refunds/${encodeURIComponent(refundId)}`,
          { headers: this.cashfreeHeaders(), timeout: 15000 },
        );
        providerRefund = fetched.data;
      } catch (fetchError: any) {
        if (fetchError?.response?.status !== 404) throw fetchError;
        const created = await axios.post(
          `${this.cashfreeBaseUrl()}/orders/${encodeURIComponent(order.cashfree_order_id)}/refunds`,
          {
            refund_amount: Number(order.total_amount),
            refund_id: refundId,
            refund_note: 'Order refund',
          },
          {
            headers: this.cashfreeHeaders(crypto.randomUUID()),
            timeout: 15000,
          },
        );
        providerRefund = created.data;
      }

      const status = String(providerRefund?.refund_status ?? 'PENDING').toUpperCase();
      await this.applyCashfreeRefundStatus(order.cashfree_order_id, refundId, status);
      return {
        success: true,
        message: status === 'SUCCESS'
          ? 'Refund processed successfully'
          : status === 'FAILED' || status === 'CANCELLED'
            ? 'Cashfree did not complete the refund; the payment remains paid'
            : status === 'ONHOLD'
              ? 'Cashfree has placed the refund on hold; reconciliation is required'
              : 'Refund submitted; awaiting Cashfree confirmation',
        refundId,
        refundStatus: status,
      };
    } catch {
      throw new BadRequestException(
        'Refund outcome is uncertain. Order remains refund_pending; reconcile with Cashfree before retrying.',
      );
    }
  }

  private async applyCashfreeRefundStatus(orderId: string, refundId: string, status: string) {
    const normalizedStatus = status.toUpperCase();
    const paymentStatus = cashfreeRefundPaymentStatus(normalizedStatus);
    const { error } = await supabase.from('orders')
      .update({
        payment_status: paymentStatus,
        cashfree_refund_status: normalizedStatus,
      })
      .eq('cashfree_order_id', orderId)
      .eq('cashfree_refund_id', refundId)
      .eq('payment_status', 'refund_pending');

    if (error) {
      throw new BadRequestException('Cashfree refund state could not be reconciled');
    }
  }

  async webhook(body: any, signature: string, timestamp: string, rawBody: Buffer) {
    const secret = process.env.CASHFREE_WEBHOOK_SECRET ?? process.env.CASHFREE_CLIENT_SECRET;
    if (!secret || !signature || !timestamp || !rawBody) {
      throw new BadRequestException('Cashfree webhook signature is missing');
    }

    if (!isCashfreeWebhookSignatureValid(signature, timestamp, rawBody, secret)) {
      throw new BadRequestException('Invalid Cashfree webhook signature');
    }

    if (!body || typeof body.type !== 'string' || !body.data || typeof body.data !== 'object') {
      throw new BadRequestException('Invalid Cashfree webhook payload');
    }

    const eventType = body.type;
    const data = body.data;

    if (eventType === 'PAYMENT_SUCCESS_WEBHOOK') {
      const orderId = data.order?.order_id;
      if (typeof orderId !== 'string') throw new BadRequestException('Invalid Cashfree order event');
      const { data: attempt } = await supabase.from('payment_attempts')
        .select('*')
        .eq('cashfree_order_id', orderId)
        .eq('payment_provider', 'cashfree')
        .maybeSingle();
      if (attempt && !attempt.order_id) {
        const payment = await this.getSuccessfulCashfreePayment(orderId, attempt);
        if (payment) await this.createOrderFromCashfreeAttempt(attempt, String(payment.cf_payment_id));
      }
    } else if (eventType === 'PAYMENT_FAILED_WEBHOOK') {
      const orderId = data.order?.order_id;
      if (typeof orderId === 'string') {
        await supabase.from('payment_attempts')
          .update({ status: 'failed' })
          .eq('cashfree_order_id', orderId)
          .eq('payment_provider', 'cashfree')
          .eq('status', 'created')
          .is('order_id', null);
      }
    } else if (eventType === 'REFUND_STATUS_WEBHOOK') {
      const orderId = data.refund?.order_id;
      const refundId = data.refund?.refund_id;
      const status = String(data.refund?.refund_status ?? '').toUpperCase();
      if (typeof orderId === 'string' && typeof refundId === 'string') {
        await this.applyCashfreeRefundStatus(orderId, refundId, status);
      }
    }

    return { success: true };
  }

  private cashfreeEnvironment(): 'SANDBOX' | 'PRODUCTION' {
    return process.env.CASHFREE_ENVIRONMENT?.toUpperCase() === 'PRODUCTION'
      ? 'PRODUCTION'
      : 'SANDBOX';
  }

  private cashfreeBaseUrl(): string {
    return this.cashfreeEnvironment() === 'PRODUCTION'
      ? 'https://api.cashfree.com/pg'
      : 'https://sandbox.cashfree.com/pg';
  }

  private cashfreeHeaders(idempotencyKey?: string) {
    const clientId = process.env.CASHFREE_CLIENT_ID;
    const clientSecret = process.env.CASHFREE_CLIENT_SECRET;
    if (!clientId || !clientSecret) {
      throw new BadRequestException('Cashfree credentials are not configured');
    }
    return {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'x-api-version': process.env.CASHFREE_API_VERSION ?? '2025-01-01',
      'x-client-id': clientId,
      'x-client-secret': clientSecret,
      ...(idempotencyKey ? { 'x-idempotency-key': idempotencyKey } : {}),
    };
  }

  private async createOrderFromCashfreeAttempt(attempt: any, cashfreePaymentId: string) {
    const { data, error } = await supabase.rpc('create_paid_order_from_cashfree_attempt', {
      p_attempt_id: attempt.id,
      p_payment_id: cashfreePaymentId,
    });

    if (error || !data?.order) {
      throw new BadRequestException(error?.message ?? 'Atomic Cashfree order conversion failed');
    }

    const order = data.order;
    if (data.created === true) {
      try {
        this.socketGateway.sendOrderUpdate(order.id, 'pending');
      } catch (e) {
        console.error('Order room status update failed:', e);
      }
      try {
        this.socketGateway.emitToPartner(order.restaurant_partner_id, 'new-order', {
          orderId: order.id,
          status: order.order_status,
          paymentStatus: 'paid',
          totalAmount: order.total_amount,
        });
      } catch (e) {
        console.error('Partner socket notification failed:', e);
      }
      try {
        await this.fcmService.sendToPartner(
          order.restaurant_partner_id,
          '🍽️ New Order!',
          `You have a new order worth ₹${order.total_amount}`,
          { orderId: order.id, screen: 'order_details' },
        );
      } catch (e) {
        console.error('Partner FCM notification failed:', e);
      }
    }

    return {
      success: true,
      message: data.created ? 'Payment verified successfully' : 'Payment already verified',
      order: {
        id: order.id,
        total: order.total_amount,
        paymentStatus: order.payment_status,
        status: order.order_status,
      },
    };
  }

}

export function isCashfreePaymentMatch(payment: any, attempt: any): boolean {
  const expectedAmount = Number(Number(attempt?.total_amount).toFixed(2));
  return (
    Number.isFinite(expectedAmount) &&
    payment?.order_id === attempt?.cashfree_order_id &&
    payment?.payment_status === 'SUCCESS' &&
    payment?.payment_currency === 'INR' &&
    Number(payment?.order_amount) === expectedAmount &&
    Number(payment?.payment_amount) === expectedAmount &&
    payment?.cf_payment_id != null &&
    String(payment.cf_payment_id).length > 0
  );
}

export function isCashfreeWebhookSignatureValid(
  signature: string,
  timestamp: string,
  rawBody: Buffer,
  secret: string,
): boolean {
  if (!signature || !timestamp || !rawBody || !secret) return false;
  const expected = crypto.createHmac('sha256', secret)
    .update(timestamp + rawBody.toString('utf8'))
    .digest('base64');
  const expectedBuffer = Buffer.from(expected);
  const receivedBuffer = Buffer.from(signature);
  return expectedBuffer.length === receivedBuffer.length &&
    crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
}


export function cashfreeRefundPaymentStatus(status: string): 'refunded' | 'paid' | 'refund_pending' {
  switch (status.toUpperCase()) {
    case 'SUCCESS':
      return 'refunded';
    case 'FAILED':
    case 'CANCELLED':
      return 'paid';
    case 'PENDING':
    case 'ONHOLD':
    default:
      return 'refund_pending';
  }
}
