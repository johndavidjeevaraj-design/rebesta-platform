import {
  Injectable,
  BadRequestException,
} from '@nestjs/common';

import { supabase } from '../supabase';

@Injectable()
export class CouponsService {
  // =====================================
  // Apply Coupon / Restaurant Offer
  // =====================================

  async applyCoupon(
    customerId: string,
    code: string,
    orderAmount: number,
    restaurantPartnerId: string,
    deliveryFee: number = 0,
  ) {
    const normalizedCode = code.trim().toUpperCase();

    if (!normalizedCode) {
      throw new BadRequestException(
        'Offer code is required',
      );
    }

    if (orderAmount <= 0) {
      throw new BadRequestException(
        'Invalid order amount',
      );
    }

    // =====================================
    // Find active offer
    // =====================================

    const { data: coupon, error } =
      await supabase
        .from('coupons')
        .select('*')
        .eq('code', normalizedCode)
        .eq('is_active', true)
        .single();

    if (error || !coupon) {
      throw new BadRequestException(
        'Invalid offer',
      );
    }

    // =====================================
    // Restaurant ownership
    // =====================================

    if (
      coupon.restaurant_partner_id &&
      coupon.restaurant_partner_id !==
        restaurantPartnerId
    ) {
      throw new BadRequestException(
        'Offer is not valid for this restaurant',
      );
    }

    // =====================================
    // Start date
    // =====================================

    const now = new Date();

    if (
      coupon.starts_at &&
      new Date(coupon.starts_at) > now
    ) {
      throw new BadRequestException(
        'Offer is not active yet',
      );
    }

    // =====================================
    // Expiry
    // =====================================

    if (
      coupon.expires_at &&
      new Date(coupon.expires_at) < now
    ) {
      throw new BadRequestException(
        'Offer expired',
      );
    }

    // =====================================
    // Minimum order
    // =====================================

    const minimumOrder =
      Number(coupon.min_order_amount ?? 0);

    if (orderAmount < minimumOrder) {
      throw new BadRequestException(
        `Minimum order ₹${minimumOrder}`,
      );
    }

    // =====================================
    // Usage limit
    // =====================================

    if (
      coupon.usage_limit !== null &&
      coupon.usage_limit !== undefined &&
      Number(coupon.used_count ?? 0) >=
        Number(coupon.usage_limit)
    ) {
      throw new BadRequestException(
        'Offer usage limit reached',
      );
    }

    // =====================================
    // One customer → one use
    // =====================================

    const { data: alreadyUsed } =
      await supabase
        .from('coupon_usages')
        .select('id')
        .eq(
          'coupon_id',
          coupon.id,
        )
        .eq(
          'customer_id',
          customerId,
        )
        .maybeSingle();

    if (alreadyUsed) {
      throw new BadRequestException(
        'Offer already used',
      );
    }

    // =====================================
    // Calculate discount
    // =====================================

    let discount = 0;

    const discountType =
      String(coupon.discount_type)
        .trim()
        .toLowerCase();

    const discountValue =
      Number(coupon.discount_value ?? 0);

    if (discountValue < 0) {
      throw new BadRequestException(
        'Invalid offer discount',
      );
    }

    // -------------------------------------
    // Percentage discount
    // -------------------------------------

    if (
      discountType === 'percentage' ||
      discountType === 'percent'
    ) {
      if (discountValue > 100) {
        throw new BadRequestException(
          'Percentage discount cannot exceed 100%',
        );
      }

      discount =
        (orderAmount * discountValue) / 100;
    }

    // -------------------------------------
    // Flat discount
    // -------------------------------------

    else if (
      discountType === 'flat' ||
      discountType === 'amount'
    ) {
      discount = discountValue;
    }

    // -------------------------------------
    // Free delivery
    // -------------------------------------

    else if (
      discountType === 'free_delivery'
    ) {
      discount = 0;
    }

    // -------------------------------------
    // Unknown type
    // -------------------------------------

    else {
      throw new BadRequestException(
        `Unsupported offer type: ${discountType}`,
      );
    }

    // =====================================
    // Maximum discount
    // =====================================

    const maxDiscount =
      coupon.max_discount !== null &&
      coupon.max_discount !== undefined
        ? Number(coupon.max_discount)
        : null;

    if (
      maxDiscount !== null &&
      maxDiscount >= 0 &&
      discount > maxDiscount
    ) {
      discount = maxDiscount;
    }

    // =====================================
    // Never discount more than subtotal
    // =====================================

    discount = Math.min(
      Math.max(discount, 0),
      orderAmount,
    );

    // =====================================
    // Free delivery
    // =====================================

    const freeDelivery =
      coupon.free_delivery === true ||
      discountType === 'free_delivery';

    const deliveryFeeDiscount =
      freeDelivery
        ? Math.max(deliveryFee, 0)
        : 0;

    const finalDeliveryFee = Math.max(
      0,
      deliveryFee - deliveryFeeDiscount,
    );

    // =====================================
    // Final payable
    // =====================================

    const payable =
      Math.max(
        0,
        orderAmount -
          discount +
          finalDeliveryFee,
      );

    // =====================================
    // Response
    // =====================================

    return {
      success: true,

      coupon,

      offer: {
        id: coupon.id,
        code: coupon.code,
        title: coupon.title,
        description: coupon.description,
        discountType,
        discountValue,
        freeDelivery,
      },

      discount,

      deliveryFee,
      deliveryFeeDiscount,
      finalDeliveryFee,

      subtotal: orderAmount,

      payable,
    };
  }

    // ============================================================
  // PARTNER
  // Get restaurant offers
  // ============================================================

  async getPartnerOffers(
    restaurantPartnerId: string,
  ) {
    const { data, error } =
      await supabase
        .from('coupons')
        .select('*')
        .eq(
          'restaurant_partner_id',
          restaurantPartnerId,
        )
        .order('created_at', {
          ascending: false,
        });

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    return {
      success: true,
      offers: data ?? [],
    };
  }

  // ============================================================
  // PARTNER
  // Create restaurant offer
  // ============================================================

  async createPartnerOffer(
    restaurantPartnerId: string,
    dto: any,
  ) {
    const code =
      dto.code.trim().toUpperCase();

    if (!code) {
      throw new BadRequestException(
        'Offer code is required',
      );
    }

    // ------------------------------------------
    // Validate discount
    // ------------------------------------------

    const discountType =
      String(dto.discountType)
        .trim()
        .toLowerCase();

    const discountValue =
      Number(dto.discountValue ?? 0);

    if (
      ![
        'percentage',
        'flat',
        'free_delivery',
      ].includes(discountType)
    ) {
      throw new BadRequestException(
        'Invalid offer type',
      );
    }

    if (discountValue < 0) {
      throw new BadRequestException(
        'Discount cannot be negative',
      );
    }

    if (
      discountType === 'percentage' &&
      discountValue > 100
    ) {
      throw new BadRequestException(
        'Percentage discount cannot exceed 100%',
      );
    }

    // ------------------------------------------
    // Check duplicate code
    // ------------------------------------------

    const { data: existing } =
      await supabase
        .from('coupons')
        .select('id')
        .eq('code', code)
        .maybeSingle();

    if (existing) {
      throw new BadRequestException(
        'Offer code already exists',
      );
    }

    // ------------------------------------------
    // Create
    // ------------------------------------------

    const { data, error } =
      await supabase
        .from('coupons')
        .insert({
          code,
          title:
            dto.title?.trim() || null,
          description:
            dto.description?.trim() || null,

          discount_type: discountType,
          discount_value: discountValue,

          max_discount:
            dto.maxDiscount ?? null,

          min_order_amount:
            dto.minOrderAmount ?? 0,

          usage_limit:
            dto.usageLimit ?? null,

          restaurant_partner_id:
            restaurantPartnerId,

          is_active: true,

          starts_at:
            dto.startsAt ?? null,

          expires_at:
            dto.expiresAt ?? null,

          free_delivery:
            dto.freeDelivery === true ||
            discountType === 'free_delivery',
        })
        .select()
        .single();

    if (error || !data) {
      throw new BadRequestException(
        error?.message ??
          'Failed to create offer',
      );
    }

    return {
      success: true,
      message: 'Offer created successfully',
      offer: data,
    };
  }

  // ============================================================
  // PARTNER
  // Update restaurant offer
  // ============================================================

  async updatePartnerOffer(
    restaurantPartnerId: string,
    couponId: string,
    dto: any,
  ) {
    // ------------------------------------------
    // Find ONLY this partner's offer
    // ------------------------------------------

    const { data: existing, error: findError } =
      await supabase
        .from('coupons')
        .select('*')
        .eq('id', couponId)
        .eq(
          'restaurant_partner_id',
          restaurantPartnerId,
        )
        .maybeSingle();

    if (findError || !existing) {
      throw new BadRequestException(
        'Offer not found',
      );
    }

    const updateData: any = {};

    // ------------------------------------------
    // Code
    // ------------------------------------------

    if (dto.code !== undefined) {
      const code =
        dto.code.trim().toUpperCase();

      if (!code) {
        throw new BadRequestException(
          'Offer code cannot be empty',
        );
      }

      if (code !== existing.code) {
        const { data: duplicate } =
          await supabase
            .from('coupons')
            .select('id')
            .eq('code', code)
            .neq('id', couponId)
            .maybeSingle();

        if (duplicate) {
          throw new BadRequestException(
            'Offer code already exists',
          );
        }
      }

      updateData.code = code;
    }

    // ------------------------------------------
    // Basic fields
    // ------------------------------------------

    if (dto.title !== undefined) {
      updateData.title =
        dto.title?.trim() || null;
    }

    if (dto.description !== undefined) {
      updateData.description =
        dto.description?.trim() || null;
    }

    // ------------------------------------------
    // Discount
    // ------------------------------------------

    const discountType =
      dto.discountType !== undefined
        ? String(dto.discountType)
            .trim()
            .toLowerCase()
        : existing.discount_type;

    const discountValue =
      dto.discountValue !== undefined
        ? Number(dto.discountValue)
        : Number(existing.discount_value);

    if (
      ![
        'percentage',
        'flat',
        'free_delivery',
      ].includes(discountType)
    ) {
      throw new BadRequestException(
        'Invalid offer type',
      );
    }

    if (discountValue < 0) {
      throw new BadRequestException(
        'Discount cannot be negative',
      );
    }

    if (
      discountType === 'percentage' &&
      discountValue > 100
    ) {
      throw new BadRequestException(
        'Percentage discount cannot exceed 100%',
      );
    }

    updateData.discount_type =
      discountType;

    updateData.discount_value =
      discountValue;

    // ------------------------------------------
    // Other fields
    // ------------------------------------------

    if (dto.maxDiscount !== undefined) {
      updateData.max_discount =
        dto.maxDiscount;
    }

    if (dto.minOrderAmount !== undefined) {
      updateData.min_order_amount =
        dto.minOrderAmount;
    }

    if (dto.usageLimit !== undefined) {
      updateData.usage_limit =
        dto.usageLimit;
    }

    if (dto.isActive !== undefined) {
      updateData.is_active =
        dto.isActive;
    }

    if (dto.startsAt !== undefined) {
      updateData.starts_at =
        dto.startsAt;
    }

    if (dto.expiresAt !== undefined) {
      updateData.expires_at =
        dto.expiresAt;
    }

    if (dto.freeDelivery !== undefined) {
      updateData.free_delivery =
        dto.freeDelivery;
    } else if (
      discountType === 'free_delivery'
    ) {
      updateData.free_delivery = true;
    }

    // ------------------------------------------
    // Update
    // ------------------------------------------

    const { data, error } =
      await supabase
        .from('coupons')
        .update(updateData)
        .eq('id', couponId)
        .eq(
          'restaurant_partner_id',
          restaurantPartnerId,
        )
        .select()
        .single();

    if (error || !data) {
      throw new BadRequestException(
        error?.message ??
          'Failed to update offer',
      );
    }

    return {
      success: true,
      message: 'Offer updated successfully',
      offer: data,
    };
  }

  // ============================================================
  // PARTNER
  // Delete / deactivate offer
  // ============================================================

  async deletePartnerOffer(
    restaurantPartnerId: string,
    couponId: string,
  ) {
    const { data, error } =
      await supabase
        .from('coupons')
        .update({
          is_active: false,
        })
        .eq('id', couponId)
        .eq(
          'restaurant_partner_id',
          restaurantPartnerId,
        )
        .select()
        .single();

    if (error || !data) {
      throw new BadRequestException(
        'Offer not found',
      );
    }

    return {
      success: true,
      message: 'Offer deactivated successfully',
      offer: data,
    };
  }
}