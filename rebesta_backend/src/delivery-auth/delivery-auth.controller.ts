import {
  Controller,
  Post,
  Get,
  Body,
  Req,
  UseGuards,
} from '@nestjs/common';

import { Throttle } from '@nestjs/throttler';


import { DeliveryAuthService } from './delivery-auth.service';

import { RegisterDeliveryDto } from './dto/register-delivery.dto';
import { LoginDeliveryDto } from './dto/login-delivery.dto';

import { DeliveryJwtGuard } from './delivery-jwt.guard';

@Controller('delivery-auth')
export class DeliveryAuthController {

  constructor(
    private readonly deliveryAuthService: DeliveryAuthService,
  ) {}

  // ===============================
  // Register
  // ===============================
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('register')
  register(
    @Body() dto: RegisterDeliveryDto,
  ) {

    return this.deliveryAuthService.register(
      dto,
    );

  }

  // ===============================
  // Login
  // ===============================
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('login')
  login(
    @Body() dto: LoginDeliveryDto,
  ) {

    return this.deliveryAuthService.login(
      dto,
    );

  }

  // ===============================
  // Profile
  // ===============================
  @Get('profile')
  @UseGuards(DeliveryJwtGuard)
  profile(
    @Req() req,
  ) {

    return this.deliveryAuthService.profile(
      req.user.deliveryPartnerId,
    );

  }

}