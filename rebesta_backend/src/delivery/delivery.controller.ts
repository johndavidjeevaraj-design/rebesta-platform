import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Req,
  Body,
  UseGuards,
} from '@nestjs/common';

import { DeliveryService } from './delivery.service';
import { DeliveryJwtGuard } from '../delivery-auth/delivery-jwt.guard';
import { UpdateDeliveryStatusDto } from './dto/update-status.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import { VerifyDeliveryOtpDto } from './dto/verify-delivery-otp.dto';

@Controller('delivery')
export class DeliveryController {
  constructor(
    private readonly deliveryService: DeliveryService,
  ) {}

  // ==========================
  // Available Orders
  // ==========================

  @Get('available-orders')
  @UseGuards(DeliveryJwtGuard)
  getAvailableOrders() {
    return this.deliveryService.getAvailableOrders();
  }

  // ==========================
  // Dashboard
  // ==========================

  @Get('dashboard')
  @UseGuards(DeliveryJwtGuard)
  dashboard(
    @Req() req,
  ) {
    return this.deliveryService.dashboard(
      req.user.deliveryPartnerId,
    );
  }

  // ==========================
  // Accept Order
  // ==========================

  @Patch('orders/:id/accept')
  @UseGuards(DeliveryJwtGuard)
  acceptOrder(
    @Req() req,
    @Param('id') orderId: string,
  ) {
    return this.deliveryService.acceptOrder(
      orderId,
      req.user.deliveryPartnerId,
    );
  }

  // ==========================
  // Pick Up Order
  // ==========================

  @Patch('orders/:id/pick-up')
  @UseGuards(DeliveryJwtGuard)
  pickUpOrder(
    @Req() req,
    @Param('id') orderId: string,
  ) {
    return this.deliveryService.pickUpOrder(
      orderId,
      req.user.deliveryPartnerId,
    );
  }

  // ==========================
  // Out For Delivery
  // ==========================

  @Patch('orders/:id/out-for-delivery')
  @UseGuards(DeliveryJwtGuard)
  outForDelivery(
    @Req() req,
    @Param('id') orderId: string,
  ) {
    return this.deliveryService.outForDelivery(
      orderId,
      req.user.deliveryPartnerId,
    );
  }

  // ==========================
  // Delivered
  // ==========================



  // ==========================
  // Online / Offline Status
  // ==========================

  @Patch('status')
  @UseGuards(DeliveryJwtGuard)
  updateStatus(
    @Req() req,
    @Body() dto: UpdateDeliveryStatusDto,
  ) {
    return this.deliveryService.updateStatus(
      req.user.deliveryPartnerId,
      dto.isOnline,
    );
  }

  // ==========================
  // Complete Delivery
  // ==========================


  // ==========================
  // Delivery History
  // ==========================

  @Get('history')
  @UseGuards(DeliveryJwtGuard)
  history(
    @Req() req,
  ) {
    return this.deliveryService.getMyDeliveries(
      req.user.deliveryPartnerId,
    );
  }

@Post('location')
@UseGuards(DeliveryJwtGuard)
updateLocation(
  @Req() req,
  @Body() dto: UpdateLocationDto,
) {

  return this.deliveryService.updateLocation(
    req.user.deliveryPartnerId,
    dto.latitude,
    dto.longitude,
  );

}

@Post('verify-otp')
@UseGuards(DeliveryJwtGuard)
verifyOtp(
  @Req() req,
  @Body() dto: VerifyDeliveryOtpDto,
) {
  return this.deliveryService.verifyOtp(
    req.user.deliveryPartnerId,
    dto,
  );
}

@Get('wallet')
@UseGuards(DeliveryJwtGuard)
wallet(
  @Req() req,
) {

  return this.deliveryService.wallet(
    req.user.deliveryPartnerId,
  );

}

@Get('earnings')
@UseGuards(DeliveryJwtGuard)
earnings(
  @Req() req,
) {

  return this.deliveryService.earnings(
    req.user.deliveryPartnerId,
  );

}

@Get('active-orders')
@UseGuards(DeliveryJwtGuard)
activeOrders(
  @Req() req,
) {
  return this.deliveryService.getActiveOrders(
    req.user.deliveryPartnerId,
  );
}

  @Patch('orders/:id/reached-pickup')
  @UseGuards(DeliveryJwtGuard)
  arriveAtRestaurant(
    @Req() req,
    @Param('id') orderId: string,
  ) {
    return this.deliveryService.arriveAtRestaurant(
      orderId,
      req.user.deliveryPartnerId,
    );
  }

  @Patch('orders/:id/reached-customer')
  @UseGuards(DeliveryJwtGuard)
  arriveAtCustomer(
    @Req() req,
    @Param('id') orderId: string,
  ) {
    return this.deliveryService.arriveAtCustomer(
      orderId,
      req.user.deliveryPartnerId,
    );
  }

  @Patch('orders/:id/cancel')
  @UseGuards(DeliveryJwtGuard)
  cancelDelivery(
    @Req() req,
    @Param('id') orderId: string,
  ) {
    return this.deliveryService.cancelDelivery(
      orderId,
      req.user.deliveryPartnerId,
    );
  }

  @Patch('orders/:id/complete')
  @UseGuards(DeliveryJwtGuard)
  completeDeliveryWithoutOtp(
    @Req() req,
    @Param('id') orderId: string,
  ) {
    return this.deliveryService.completeDeliveryWithoutOtp(
      orderId,
      req.user.deliveryPartnerId,
    );
  }
}