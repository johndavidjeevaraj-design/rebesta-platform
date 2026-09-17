import {
  Controller,
  Get,
  Patch,
  Body,
  Req,
  UseGuards,
} from '@nestjs/common';

import { PartnersService } from './partners.service';
import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';

@Controller('partners')
@UseGuards(JwtAuthGuard)
export class PartnersController {
  constructor(
    private readonly partnersService: PartnersService,
  ) {}

  // Get logged-in partner profile
  @Get('profile')
  getProfile(@Req() req) {
    return this.partnersService.getProfile(
      req.user.restaurantPartnerId,
    );
  }

  // Update restaurant profile
  @Patch('profile')
  updateProfile(
    @Req() req,
    @Body() body: any,
  ) {
    return this.partnersService.updateProfile(
      req.user.restaurantPartnerId,
      body,
    );
  }
}