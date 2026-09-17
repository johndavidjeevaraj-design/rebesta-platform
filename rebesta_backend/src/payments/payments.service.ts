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
      menuItemId: string;
      quantity: number;
      price: number;
    }> = [];

    let subtotal = 0;

    for (const item of cartItems) {
      const { data: menuItem, error: menuError } = await supabase
        .from('menu_items')
        .select('id, price, is_available')
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

      const quantity = Number(item.quantity ?? 0);
      const price = Number(menuItem.price ?? 0);

      snapshot.push({
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

if (totalAmount <= 0) {
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

if (
  razorpayPayment.order_id !== dto.razorpayOrderId
) {
  throw new BadRequestException(
    'Payment does not belong to this order',
  );
}

// ----------------------------------------------------------
// PAYMENT MUST BE CAPTURED
// ----------------------------------------------------------

if (razorpayPayment.status !== 'captured') {
  throw new BadRequestException(
    `Payment is not captured: ${razorpayPayment.status}`,
  );
}

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
  await supabase
    .from('payment_attempts')
    .update({ status: 'failed' })
    .eq('id', attempt.id);

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

    if (attempt.status === 'failed') {
      return { success: true, state: 'failed', order: null };
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
      .select('*')
      .eq('id', orderId)
      .single();

    if (error || !order) {
      throw new BadRequestException('Order not found');
    }

    if (!order.razorpay_payment_id) {
      throw new BadRequestException('Payment not found');
    }

    await this.razorpay.payments.refund(order.razorpay_payment_id, {});

    await supabase
      .from('orders')
      .update({ payment_status: 'refunded' })
      .eq('id', orderId);

    return { success: true, message: 'Refund processed successfully' };
  }

  // ============================================================
  // WEBHOOK (server-side safety net)
  // ============================================================

async webhook(
  body: any,
  signature: string,
  rawBody: Buffer,
) {
  if (!signature || !rawBody) {
    throw new BadRequestException(
      'Missing webhook signature',
    );
  }

  const expectedSignature = crypto
    .createHmac(
      'sha256',
      process.env.RAZORPAY_WEBHOOK_SECRET!,
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

  const event = body.event;

  // existing webhook logic...


    if (event === 'payment.captured') {
      const payment = body.payload.payment.entity;

      const { data: attempt } = await supabase
        .from('payment_attempts')
        .select('*')
        .eq('razorpay_order_id', payment.order_id)
        .maybeSingle();

      if (attempt) {
        await this.createOrderFromAttempt(attempt, payment.id, null).catch(
          (e) => console.error('Webhook order creation failed:', e),
        );
      }
    }

    if (event === 'payment.failed') {
      const payment = body.payload.payment.entity;

      await supabase
        .from('payment_attempts')
        .update({ status: 'failed' })
        .eq('razorpay_order_id', payment.order_id);
    }

    if (event === 'refund.processed') {
      const refund = body.payload.refund.entity;

      await supabase
        .from('orders')
        .update({ payment_status: 'refunded' })
        .eq('razorpay_payment_id', refund.payment_id);
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
    // Re-fetch attempt fresh to avoid a race between the two
    // triggers (client verify + webhook) both passing the
    // earlier idempotency check at nearly the same time.

    const { data: freshAttempt, error: freshError } = await supabase
      .from('payment_attempts')
      .select('*')
      .eq('id', attempt.id)
      .single();

    if (freshError || !freshAttempt) {
      throw new BadRequestException('Payment attempt not found');
    }

    if (freshAttempt.order_id) {
      const { data: existingOrder } = await supabase
        .from('orders')
        .select('id, order_status, payment_status, total_amount')
        .eq('id', freshAttempt.order_id)
        .single();

      return {
        success: true,
        message: 'Payment already verified',
        order: existingOrder,
      };
    }

    const deliveryOtp = Math.floor(
      1000 + Math.random() * 9000,
    ).toString();

    const { data: order, error: orderError } = await supabase
      .from('orders')
      .insert({
        customer_id: freshAttempt.customer_id,
        restaurant_partner_id: freshAttempt.restaurant_partner_id,
        address_id: freshAttempt.address_id,
        discount_amount: freshAttempt.discount_amount,
        delivery_fee: freshAttempt.delivery_fee,
        total_amount: freshAttempt.total_amount,
        payment_status: 'paid',
        order_status: 'pending',
        razorpay_order_id: freshAttempt.razorpay_order_id,
        razorpay_payment_id: razorpayPaymentId,
        razorpay_signature: signature,
        payment_completed_at: new Date().toISOString(),
        delivery_otp: deliveryOtp,
        otp_verified: false,
      })
      .select()
      .single();

    if (orderError || !order) {
      // Handle the rare race where two triggers both passed the
      // idempotency check and both tried to insert. A unique
      // constraint on orders.razorpay_order_id (add via SQL
      // below) makes the second insert fail safely here.
      const { data: raceOrder } = await supabase
        .from('orders')
        .select('id, order_status, payment_status, total_amount')
        .eq('razorpay_order_id', freshAttempt.razorpay_order_id)
        .maybeSingle();

      if (raceOrder) {
        return {
          success: true,
          message: 'Payment already verified',
          order: raceOrder,
        };
      }

      throw new BadRequestException(
        orderError?.message ?? 'Failed to create order',
      );
    }

    const snapshot = freshAttempt.cart_items_snapshot as Array<{
      menuItemId: string;
      quantity: number;
      price: number;
    }>;

    const orderItems = snapshot.map((item) => ({
      order_id: order.id,
      menu_id: item.menuItemId,
      quantity: item.quantity,
      price: item.price,
    }));

    const { error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItems);

    if (itemsError) {
      await supabase.from('orders').delete().eq('id', order.id);
      throw new BadRequestException(itemsError.message);
    }

    await supabase
      .from('payment_attempts')
      .update({
        status: 'success',
        razorpay_payment_id: razorpayPaymentId,
        razorpay_signature: signature,
        order_id: order.id,
      })
      .eq('id', freshAttempt.id);

    const { data: cart } = await supabase
      .from('carts')
      .select('id')
      .eq('customer_id', freshAttempt.customer_id)
      .eq('restaurant_partner_id', freshAttempt.restaurant_partner_id)
      .maybeSingle();

    if (cart) {
      await supabase.from('cart_items').delete().eq('cart_id', cart.id);
    }

    try {
      this.socketGateway.sendOrderUpdate(order.id, 'pending');
    } catch (e) {
      console.error('Partner socket notification failed:', e);
    }

    try {
      await this.fcmService.sendToPartner(
        freshAttempt.restaurant_partner_id,
        '🍽️ New Order!',
        `You have a new order worth ₹${order.total_amount}`,
        { orderId: order.id, screen: 'order_details' },
      );
    } catch (e) {
      console.error('Partner FCM notification failed:', e);
    }

    return {
      success: true,
      message: 'Payment verified successfully',
      order: {
        id: order.id,
        total: order.total_amount,
        paymentStatus: order.payment_status,
        status: order.order_status,
      },
    };
  }
}