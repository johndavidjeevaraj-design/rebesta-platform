import {
  Body,
  Controller,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { FcmService } from './fcm.service';

import { RegisterTokenDto } from './dto/register-token.dto';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';
import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';

import { DeliveryJwtGuard } from '../delivery-auth/delivery-jwt.guard';

@Controller('fcm')
export class FcmController {

  constructor(
    private readonly fcmService: FcmService,
  ) {}

  @Post('customer')
  @UseGuards(CustomerJwtGuard)
  customer(
    @Req() req,
    @Body() dto: RegisterTokenDto,
  ) {
    return this.fcmService.registerCustomerToken(
      req.user.customerId,
      dto,
    );
  }

  @Post('partner')
  @UseGuards(JwtAuthGuard)
  partner(
    @Req() req,
    @Body() dto: RegisterTokenDto,
  ) {
    return this.fcmService.registerPartnerToken(
      req.user.restaurantPartnerId,
      dto,
    );
  }

  @Post('delivery')
  @UseGuards(DeliveryJwtGuard)
  delivery(
    @Req() req,
    @Body() dto: RegisterTokenDto,
  ) {
    return this.fcmService.registerDeliveryToken(
      req.user.deliveryPartnerId,
      dto,
    );
  }

}