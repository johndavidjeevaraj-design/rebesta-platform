import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { ReviewsService } from './reviews.service';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';

import { CreateReviewDto } from './dto/create-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';

@Controller('reviews')
export class ReviewsController {
  constructor(
    private readonly reviewsService: ReviewsService,
  ) {}

  // ===============================
  // Create Review
  // ===============================

  @Post()
  @UseGuards(CustomerJwtGuard)
  create(
    @Req() req,
    @Body() dto: CreateReviewDto,
  ) {
    return this.reviewsService.createReview(
      req.user.customerId,
      dto,
    );
  }

  // ===============================
  // My Reviews
  // ===============================

  @Get('my')
  @UseGuards(CustomerJwtGuard)
  myReviews(
    @Req() req,
  ) {
    return this.reviewsService.getMyReviews(
      req.user.customerId,
    );
  }

  // ===============================
  // Restaurant Reviews
  // ===============================

  @Get('restaurant/:restaurantId')
  restaurantReviews(
    @Param('restaurantId')
    restaurantId: string,
  ) {
    return this.reviewsService.getRestaurantReviews(
      restaurantId,
    );
  }

  // ===============================
  // Delivery Partner Reviews
  // ===============================

  @Get('delivery-partner/:deliveryPartnerId')
  deliveryReviews(
    @Param('deliveryPartnerId')
    deliveryPartnerId: string,
  ) {
    return this.reviewsService.getDeliveryPartnerReviews(
      deliveryPartnerId,
    );
  }

  // ===============================
  // Update Review
  // ===============================

  @Patch(':id')
  @UseGuards(CustomerJwtGuard)
  update(
    @Req() req,
    @Param('id')
    reviewId: string,
    @Body()
    dto: UpdateReviewDto,
  ) {
    return this.reviewsService.updateReview(
      req.user.customerId,
      reviewId,
      dto,
    );
  }

  // ===============================
  // Delete Review
  // ===============================

  @Delete(':id')
  @UseGuards(CustomerJwtGuard)
  delete(
    @Req() req,
    @Param('id')
    reviewId: string,
  ) {
    return this.reviewsService.deleteReview(
      req.user.customerId,
      reviewId,
    );
  }
}