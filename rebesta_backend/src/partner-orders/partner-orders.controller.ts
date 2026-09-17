import {
  Controller,
  Get,
  Req,
  UseGuards,
  Patch,
  Param,
  Body,
} from '@nestjs/common';

import { PartnerOrdersService } from './partner-orders.service';

import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Controller('partner-orders')
export class PartnerOrdersController {


  constructor(
    private readonly partnerOrdersService: PartnerOrdersService,
  ) {}



  // Get partner orders
  @Get()
  @UseGuards(JwtAuthGuard)
  getOrders(
    @Req() req,
  ) {

    return this.partnerOrdersService.getPartnerOrders(
      req.user.restaurantPartnerId,
    );

  }




  // Update order status

  @Patch(':id/status')
  @UseGuards(JwtAuthGuard)
  updateStatus(
    @Req() req,
    @Param('id') id:string,
    @Body() body:UpdateOrderStatusDto
  ) {


    return this.partnerOrdersService.updateStatus(
      id,
      body.status,
      req.user.restaurantPartnerId,
    );

  }

@Get(':id')
@UseGuards(JwtAuthGuard)
getOrderById(
  @Req() req,
  @Param('id') id: string,
) {
  return this.partnerOrdersService.getOrderById(
    id,
    req.user.restaurantPartnerId,
  );
}


}