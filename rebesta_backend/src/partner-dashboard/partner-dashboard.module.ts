import { Module } from '@nestjs/common';
import { PartnerDashboardController } from './partner-dashboard.controller';
import { PartnerDashboardService } from './partner-dashboard.service';

@Module({
  controllers: [PartnerDashboardController],
  providers: [PartnerDashboardService],
})
export class PartnerDashboardModule {}