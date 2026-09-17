import {
  Controller,
  Get,
  Post,
  Req,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';

import { OrdersService } from './orders.service';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';

import { CreateOrderDto } from './dto/create-order.dto';
import { IsOptional, IsString } from 'class-validator';


@Controller('orders')
export class OrdersController {
  constructor(
    private readonly ordersService: OrdersService,
  ) {}

  // Checkout
  @Post('checkout')
  @UseGuards(CustomerJwtGuard)
  checkout(
    @Req() req,
    @Body() dto: CreateOrderDto,
  ) {
    return this.ordersService.checkout(
      req.user.customerId,
      dto,
    );
  }

  // Customer Order History
 

@Get('my')
@UseGuards(CustomerJwtGuard)
getMyOrders(@Req() req) {
  return this.ordersService.getCustomerOrders(
    req.user.customerId,
  );
}



@Get(':id/tracking')
@UseGuards(CustomerJwtGuard)
trackOrder(
  @Req() req,
  @Param('id') id: string,
) {
  return this.ordersService.trackOrder(
    req.user.customerId,
    id,
  );
}

@Get(':id')
@UseGuards(CustomerJwtGuard)
getOrderById(
  @Req() req,
  @Param('id') id: string,
) {
  return this.ordersService.getOrderById(
    req.user.customerId,
    id,
  );
}
}