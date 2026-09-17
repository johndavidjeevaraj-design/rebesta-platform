import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';

import { supabase } from '../supabase';

import { CreateReviewDto } from './dto/create-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';

@Injectable()
export class ReviewsService {

  private async updateRestaurantRating(
    restaurantPartnerId: string,
  ) {

    const { data: reviews, error } =
      await supabase
        .from('reviews')
        .select('restaurant_rating')
        .eq(
          'restaurant_partner_id',
          restaurantPartnerId,
        );

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    const totalReviews = reviews.length;

    const average =
      totalReviews === 0
        ? 0
        : reviews.reduce(
            (sum: number, review: any) =>
              sum +
              Number(review.restaurant_rating),
            0,
          ) / totalReviews;

    await supabase
      .from('restaurant_partners')
      .update({
        rating: Number(average.toFixed(2)),
        total_reviews: totalReviews,
      })
      .eq('id', restaurantPartnerId);
  }

    private async updateDeliveryRating(
    deliveryPartnerId: string,
  ) {

    const { data: reviews, error } =
      await supabase
        .from('reviews')
        .select('delivery_rating')
        .eq(
          'delivery_partner_id',
          deliveryPartnerId,
        );

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    const validReviews =
      reviews.filter(
        (r: any) =>
          r.delivery_rating !== null,
      );

    const totalReviews =
      validReviews.length;

    const average =
      totalReviews === 0
        ? 0
        : validReviews.reduce(
            (sum: number, review: any) =>
              sum +
              Number(review.delivery_rating),
            0,
          ) / totalReviews;

    await supabase
      .from('delivery_partners')
      .update({
        rating: Number(average.toFixed(2)),
        total_reviews: totalReviews,
      })
      .eq('id', deliveryPartnerId);
  }

  async createReview(
  customerId: string,
  dto: CreateReviewDto,
) {

  // Verify order

  const { data: order, error } =
    await supabase
      .from('orders')
      .select('*')
      .eq('id', dto.orderId)
      .eq('customer_id', customerId)
      .single();

  if (error || !order) {
    throw new BadRequestException(
      'Order not found',
    );
  }

  // Delivered only

  if (
    order.order_status !==
    'delivered'
  ) {
    throw new BadRequestException(
      'Only delivered orders can be reviewed',
    );
  }

  // One review only

  const { data: existing } =
    await supabase
      .from('reviews')
      .select('id')
      .eq('order_id', dto.orderId)
      .maybeSingle();

  if (existing) {
    throw new BadRequestException(
      'Review already submitted',
    );
  }

  // Insert

  const { data: review, error: reviewError } =
    await supabase
      .from('reviews')
      .insert({

        order_id:
          dto.orderId,

        customer_id:
          customerId,

        restaurant_partner_id:
          order.restaurant_partner_id,

        delivery_partner_id:
          order.delivery_partner_id,

        restaurant_rating:
          dto.restaurantRating,

        delivery_rating:
          dto.deliveryRating,

        review:
          dto.review,

      })
      .select()
      .single();

  if (reviewError) {
    throw new BadRequestException(
      reviewError.message,
    );
  }

  // Update ratings

  await this.updateRestaurantRating(
    order.restaurant_partner_id,
  );

  if (
    order.delivery_partner_id &&
    dto.deliveryRating
  ) {
    await this.updateDeliveryRating(
      order.delivery_partner_id,
    );
  }

  return {

    success: true,

    message:
      'Review submitted successfully',

    review,

  };
}

async getMyReviews(
  customerId: string,
) {

  const { data, error } =
    await supabase
      .from('reviews')
      .select(`
        id,
        restaurant_rating,
        delivery_rating,
        review,
        created_at,

        restaurant_partners (
          restaurant_name,
          logo_url
        )
      `)
      .eq('customer_id', customerId)
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

    reviews: data,

  };

}
async getRestaurantReviews(
  restaurantPartnerId: string,
) {

  const { data, error } =
    await supabase
      .from('reviews')
      .select(`
        id,
        restaurant_rating,
        review,
        created_at,

        customers (
          id,
          name
        )
      `)
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

    reviews: data,

  };

}
async getDeliveryPartnerReviews(
  deliveryPartnerId: string,
) {

  const { data, error } =
    await supabase
      .from('reviews')
      .select(`
        id,
        delivery_rating,
        review,
        created_at,

        customers (
          id,
          name
        )
      `)
      .eq(
        'delivery_partner_id',
        deliveryPartnerId,
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

    reviews: data,

  };

}
async updateReview(
  customerId: string,
  reviewId: string,
  dto: UpdateReviewDto,
) {

  const { data: review, error } =
    await supabase
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .eq('customer_id', customerId)
      .single();

  if (error || !review) {
    throw new BadRequestException(
      'Review not found',
    );
  }

  const { data: updated, error: updateError } =
    await supabase
      .from('reviews')
      .update({

        restaurant_rating:
          dto.restaurantRating ??
          review.restaurant_rating,

        delivery_rating:
          dto.deliveryRating ??
          review.delivery_rating,

        review:
          dto.review ??
          review.review,

        updated_at:
          new Date(),

      })
      .eq('id', reviewId)
      .select()
      .single();

  if (updateError) {
    throw new BadRequestException(
      updateError.message,
    );
  }

  await this.updateRestaurantRating(
    review.restaurant_partner_id,
  );

  if (review.delivery_partner_id) {

    await this.updateDeliveryRating(
      review.delivery_partner_id,
    );

  }

  return {

    success: true,

    message: 'Review updated',

    review: updated,

  };

}
async deleteReview(
  customerId: string,
  reviewId: string,
) {

  const { data: review, error } =
    await supabase
      .from('reviews')
      .select('*')
      .eq('id', reviewId)
      .eq('customer_id', customerId)
      .single();

  if (error || !review) {
    throw new BadRequestException(
      'Review not found',
    );
  }

  await supabase
    .from('reviews')
    .delete()
    .eq('id', reviewId);

  await this.updateRestaurantRating(
    review.restaurant_partner_id,
  );

  if (review.delivery_partner_id) {

    await this.updateDeliveryRating(
      review.delivery_partner_id,
    );

  }

  return {

    success: true,

    message: 'Review deleted',

  };

}
}