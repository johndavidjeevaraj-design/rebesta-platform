import {
  Controller,
  Get,
  Req,
  UseGuards,
} from '@nestjs/common';

import { PartnerDashboardService } from './partner-dashboard.service';
import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';

@Controller('partner/dashboard')
export class PartnerDashboardController {

  constructor(
    private readonly partnerDashboardService: PartnerDashboardService,
  ) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  getDashboard(
    @Req() req,
  ) {
    return this.partnerDashboardService.getDashboard(
      req.user.restaurantPartnerId,
    );
  }

}