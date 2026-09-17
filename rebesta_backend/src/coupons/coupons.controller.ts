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

import { CouponsService } from './coupons.service';

import { ApplyCouponDto } from './dto/apply-coupon.dto';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { UpdateCouponDto } from './dto/update-coupon.dto';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';
import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';

@Controller('coupons')
export class CouponsController {
  constructor(
    private readonly couponsService: CouponsService,
  ) {}

  // ============================================================
  // CUSTOMER
  // Apply restaurant offer
  // ============================================================

  @Post('apply')
  @UseGuards(CustomerJwtGuard)
  apply(
    @Req() req,
    @Body() dto: ApplyCouponDto,
  ) {
    return this.couponsService.applyCoupon(
      req.user.customerId,
      dto.code,
      dto.orderAmount,
      dto.restaurantPartnerId,
    );
  }

  // ============================================================
  // PARTNER
  // Get my restaurant offers
  // ============================================================

  @Get('partner')
  @UseGuards(JwtAuthGuard)
  getPartnerOffers(@Req() req) {
    return this.couponsService.getPartnerOffers(
      req.user.restaurantPartnerId,
    );
  }

  // ============================================================
  // PARTNER
  // Create offer
  // ============================================================

  @Post('partner')
  @UseGuards(JwtAuthGuard)
  createPartnerOffer(
    @Req() req,
    @Body() dto: CreateCouponDto,
  ) {
    return this.couponsService.createPartnerOffer(
      req.user.restaurantPartnerId,
      dto,
    );
  }

  // ============================================================
  // PARTNER
  // Update offer
  // ============================================================

  @Patch('partner/:id')
  @UseGuards(JwtAuthGuard)
  updatePartnerOffer(
    @Req() req,
    @Param('id') id: string,
    @Body() dto: UpdateCouponDto,
  ) {
    return this.couponsService.updatePartnerOffer(
      req.user.restaurantPartnerId,
      id,
      dto,
    );
  }

  // ============================================================
  // PARTNER
  // Activate / Deactivate / Edit
  // ============================================================

  @Delete('partner/:id')
  @UseGuards(JwtAuthGuard)
  deletePartnerOffer(
    @Req() req,
    @Param('id') id: string,
  ) {
    return this.couponsService.deletePartnerOffer(
      req.user.restaurantPartnerId,
      id,
    );
  }
}