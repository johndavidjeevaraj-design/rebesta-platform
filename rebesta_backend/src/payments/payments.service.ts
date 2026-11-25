import {
  Injectable,
  BadRequestException,
} from '@nestjs/common';

import Razorpay from 'razorpay';
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

  private razorpay: Razorpay;

  constructor(
    private readonly socketGateway: SocketGateway,
    private readonly fcmService: FcmService,
    private readonly mapsService: MapsService,
    private readonly couponsService: CouponsService,
  ) {
    this.razorpay = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID!,
      key_secret: process.env.RAZORPAY_KEY_SECRET!,
    });
  }

  // ============================================================
  // CREATE CHECKOUT PAYMENT
  //
  // Validates cart, calculates price server-side, creates a
  // Razorpay order, and stores a payment_attempts row.
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

const totalAmount =
  subtotal +
  finalDeliveryFee -
  discount;

if (!Number.isFinite(totalAmount) || totalAmount <= 0 || !Number.isSafeInteger(Math.round(totalAmount * 100))) {
  throw new BadRequestException(
    'Invalid order amount',
  );
}
    // ----------------------------------------------------------
    // CREATE RAZORPAY ORDER
    // ----------------------------------------------------------

    const razorpayOrder = await this.razorpay.orders.create({
      amount: Math.round(totalAmount * 100),
      currency: 'INR',
      receipt: `attempt_${Date.now()}`,
    });

    // ----------------------------------------------------------
    // STORE PAYMENT ATTEMPT (NOT an order)
    // ----------------------------------------------------------

    const { error: insertError } = await supabase
      .from('payment_attempts')
      .insert({
        customer_id: customerId,
        restaurant_partner_id: dto.restaurantPartnerId,
        address_id: isPickup
        ? null
        : dto.addressId,
        subtotal,
        discount_amount: discount,
        delivery_fee: finalDeliveryFee,
        total_amount: totalAmount,
        coupon_code: dto.couponCode ?? null,
        cart_items_snapshot: snapshot,
        razorpay_order_id: razorpayOrder.id,
        status: 'created',
      });

    if (insertError) {
      throw new BadRequestException(insertError.message);
    }

    return {
  success: true,

  key: process.env.RAZORPAY_KEY_ID,

  orderId: razorpayOrder.id,

  amount: razorpayOrder.amount,

  currency: razorpayOrder.currency,

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
        freeDelivery:
          appliedCoupon.free_delivery === true,
      }
    : null,
};
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

  private assertCapturedPaymentMatchesAttempt(
    payment: { order_id?: string; status?: string; amount?: number; currency?: string },
    attempt: { razorpay_order_id: string; total_amount: number | string },
  ) {
    const expectedAmount = Math.round(Number(attempt.total_amount) * 100);
    if (
      payment.order_id !== attempt.razorpay_order_id ||
      payment.status !== 'captured' ||
      payment.currency !== 'INR' ||
      !Number.isSafeInteger(expectedAmount) ||
      payment.amount !== expectedAmount
    ) {
      throw new BadRequestException('Captured payment does not match the expected order amount and currency');
    }
  }

  async verifyPayment(
    customerId: string,
    dto: VerifyPaymentDto,
  ) {
    const { data: attempt, error: attemptError } = await supabase
      .from('payment_attempts')
      .select('*')
      .eq('razorpay_order_id', dto.razorpayOrderId)
      .eq('customer_id', customerId)
      .single();

    if (attemptError || !attempt) {
      throw new BadRequestException('Payment attempt not found');
    }

    if (attempt.order_id) {
      const { data: existingOrder } = await supabase
        .from('orders')
        .select('id, order_status, payment_status, total_amount')
        .eq('id', attempt.order_id)
        .single();

      return {
        success: true,
        message: 'Payment already verified',
        order: existingOrder,
      };
    }

  const razorpayPayment =
  await this.razorpay.payments.fetch(
    dto.razorpayPaymentId,
  );

// ----------------------------------------------------------
// PAYMENT MUST BELONG TO THIS RAZORPAY ORDER
// ----------------------------------------------------------

this.assertCapturedPaymentMatchesAttempt(razorpayPayment, attempt);

// ----------------------------------------------------------
// VERIFY RAZORPAY CHECKOUT SIGNATURE
// ----------------------------------------------------------

const body =
  dto.razorpayOrderId +
  '|' +
  dto.razorpayPaymentId;

const expectedSignature = crypto
  .createHmac(
    'sha256',
    process.env.RAZORPAY_KEY_SECRET!,
  )
  .update(body)
  .digest('hex');

const expectedBuffer = Buffer.from(
  expectedSignature,
  'utf8',
);

const signatureBuffer = Buffer.from(
  dto.signature,
  'utf8',
);

if (
  expectedBuffer.length !== signatureBuffer.length ||
  !crypto.timingSafeEqual(
    expectedBuffer,
    signatureBuffer,
  )
) {
  // Do not poison the attempt on a client signature failure.
  // A separately verified captured webhook/reconciliation can still recover it.

  throw new BadRequestException(
    'Invalid payment signature',
  );
}

return this.createOrderFromAttempt(
  attempt,
  dto.razorpayPaymentId,
  dto.signature,
);
  }

  // ============================================================
  // RECONCILE (app-reopen path — spec #11/#27)
  //
  // Client calls this when it doesn't know the outcome of a
  // payment (e.g. app was killed after Razorpay closed but
  // before verify() completed). Looks up by razorpay_order_id
  // and returns whatever the true current state is — creating
  // the order itself if Razorpay confirms success but our own
  // records haven't caught up yet.
  // ============================================================

  async reconcilePayment(
    customerId: string,
    razorpayOrderId: string,
  ) {
    const { data: attempt, error: attemptError } = await supabase
      .from('payment_attempts')
      .select('*')
      .eq('razorpay_order_id', razorpayOrderId)
      .eq('customer_id', customerId)
      .single();

    if (attemptError || !attempt) {
      throw new BadRequestException('Payment attempt not found');
    }

    if (attempt.order_id) {
      const { data: existingOrder } = await supabase
        .from('orders')
        .select('id, order_status, payment_status, total_amount')
        .eq('id', attempt.order_id)
        .single();

      return {
        success: true,
        state: 'confirmed',
        order: existingOrder,
      };
    }

    // Ask Razorpay directly what actually happened to this order.
    const razorpayOrder = await this.razorpay.orders.fetch(razorpayOrderId);

    if (razorpayOrder.status === 'paid') {
      const payments = await this.razorpay.orders.fetchPayments(
        razorpayOrderId,
      );

      const capturedPayment = payments.items.find(
        (p: any) => p.status === 'captured',
      );

      if (capturedPayment) {
        this.assertCapturedPaymentMatchesAttempt(capturedPayment, attempt);
        const result = await this.createOrderFromAttempt(
          attempt,
          capturedPayment.id,
          null,
        );

        return { success: true, state: 'confirmed', order: result.order };
      }
    }

    return { success: true, state: 'pending', order: null };
  }

  // ===========================================
  // Refund (unchanged)
  // ===========================================

  async refund(orderId: string) {
    const { data: order, error } = await supabase
      .from('orders')
      .select('id, payment_status, razorpay_payment_id')
      .eq('id', orderId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }
    if (order.payment_status === 'refunded') {
      throw new BadRequestException('Order has already been refunded');
    }
    if (order.payment_status !== 'paid') {
      throw new BadRequestException('Only paid orders can be refunded');
    }
    if (!order.razorpay_payment_id) {
      throw new BadRequestException('Payment not found');
    }

    // Atomically claim the refund operation to prevent concurrent duplicate calls.
    const { data: claimed, error: claimError } = await supabase
      .from('orders')
      .update({ payment_status: 'refund_pending' })
      .eq('id', orderId)
      .eq('payment_status', 'paid')
      .select('id')
      .maybeSingle();

    if (claimError || !claimed) {
      throw new BadRequestException(
        'Refund is already being processed or order state changed',
      );
    }

    let providerRefund: any;
    try {
      providerRefund = await this.razorpay.payments.refund(
        order.razorpay_payment_id,
        {},
      );
    } catch (providerError) {
      // Network errors can be ambiguous: Razorpay may have accepted the refund
      // before the response was lost. Keep refund_pending to block duplicate
      // attempts until the provider state is reconciled or refund.failed arrives.
      throw new BadRequestException(
        'Refund outcome is uncertain. Order remains refund_pending; reconcile with Razorpay before retrying.',
      );
    }

    const { data: updatedOrder, error: updateError } = await supabase
      .from('orders')
      .update({ payment_status: 'refunded' })
      .eq('id', orderId)
      .eq('payment_status', 'refund_pending')
      .select('id')
      .maybeSingle();

    if (updateError || !updatedOrder) {
      throw new BadRequestException(
        'Refund was accepted by Razorpay but order status update failed. Reconcile this order before retrying.',
      );
    }

    return {
      success: true,
      message: 'Refund processed successfully',
      refundId: providerRefund?.id ?? null,
    };
  }
  // ============================================================
  // WEBHOOK (server-side safety net)
  // ============================================================

async webhook(
  body: any,
  signature: string,
  rawBody: Buffer,
) {
  const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;
  if (!signature || !rawBody || !webhookSecret) {
    throw new BadRequestException(
      'Webhook signature or secret is missing',
    );
  }

  const expectedSignature = crypto
    .createHmac(
      'sha256',
      webhookSecret,
    )
    .update(rawBody)
    .digest('hex');

  const expectedBuffer = Buffer.from(
    expectedSignature,
    'utf8',
  );

  const signatureBuffer = Buffer.from(
    signature,
    'utf8',
  );

  if (
    expectedBuffer.length !== signatureBuffer.length ||
    !crypto.timingSafeEqual(
      expectedBuffer,
      signatureBuffer,
    )
  ) {
    throw new BadRequestException(
      'Invalid webhook signature',
    );
  }

  if (
    !body ||
    typeof body !== 'object' ||
    typeof body.event !== 'string' ||
    body.event.length === 0
  ) {
    throw new BadRequestException('Invalid webhook payload');
  }

  const event = body.event;
  const payload = body.payload;

  // Validate event envelopes before accessing nested entities.
  if (
    ['payment.captured', 'payment.failed', 'refund.processed', 'refund.failed'].includes(event) &&
    (!payload || typeof payload !== 'object')
  ) {
    throw new BadRequestException('Invalid webhook payload');
  }

  if (
    ['payment.captured', 'payment.failed'].includes(event) &&
    (!payload.payment?.entity ||
      typeof payload.payment.entity.id !== 'string' ||
      typeof payload.payment.entity.order_id !== 'string')
  ) {
    throw new BadRequestException('Invalid payment webhook entity');
  }

  if (
    ['refund.processed', 'refund.failed'].includes(event) &&
    (!payload.refund?.entity ||
      typeof payload.refund.entity.payment_id !== 'string')
  ) {
    throw new BadRequestException('Invalid refund webhook entity');
  }

  // existing webhook logic...


    if (event === 'payment.captured') {
      const payment = body.payload.payment.entity;

      const { data: attempt } = await supabase
        .from('payment_attempts')
        .select('*')
        .eq('razorpay_order_id', payment.order_id)
        .maybeSingle();

      if (attempt && payment.status === 'captured') {
        try {
          this.assertCapturedPaymentMatchesAttempt(payment, attempt);
          await this.createOrderFromAttempt(attempt, payment.id, null);
        } catch (e) {
          console.error('Webhook order creation failed:', e);
        }
      }
    }

    if (event === 'payment.failed') {
      const payment = body.payload.payment.entity;

      await supabase
        .from('payment_attempts')
        .update({ status: 'failed' })
        .eq('razorpay_order_id', payment.order_id)
        .eq('status', 'created');
    }

    if (event === 'refund.processed') {
      const refund = body.payload.refund.entity;

      // Only finalize an order currently awaiting refund. This prevents a
      // stale/duplicate refund webhook from changing unrelated order states.
      await supabase
        .from('orders')
        .update({ payment_status: 'refunded' })
        .eq('razorpay_payment_id', refund.payment_id)
        .eq('payment_status', 'refund_pending');
    }

    if (event === 'refund.failed') {
      const refund = body.payload.refund.entity;

      await supabase
        .from('orders')
        .update({ payment_status: 'paid' })
        .eq('razorpay_payment_id', refund.payment_id)
        .eq('payment_status', 'refund_pending');
    }

    return { success: true };
  }
    // ============================================================
  // INTERNAL: Create the real order from a verified payment
  // attempt. Called by BOTH the client verify() endpoint and
  // the webhook — each does its OWN signature check before
  // calling this, so this method itself does not re-verify.
  //
  // Idempotent: safe to call twice for the same attempt.
  // ============================================================

  private async createOrderFromAttempt(
    attempt: any,
    razorpayPaymentId: string,
    signature: string | null,
  ) {
    const { data, error } = await supabase.rpc('create_paid_order_from_attempt', {
      p_attempt_id: attempt.id,
      p_payment_id: razorpayPaymentId,
      p_signature: signature,
    });

    if (error || !data?.order) {
      throw new BadRequestException(
        error?.message ?? 'Atomic order conversion failed',
      );
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