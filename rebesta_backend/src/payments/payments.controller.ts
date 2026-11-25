import {
  Body,
  Controller,
  Param,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { PaymentsService } from './payments.service';

import { CreateCheckoutPaymentDto } from './dto/create-checkout-payment.dto';
import { VerifyPaymentDto } from './dto/verify-payment.dto';
import { ReconcilePaymentDto } from './dto/reconcile-payment.dto';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';
import { AdminGuard } from '../admin/admin.guard';
import { Throttle } from '@nestjs/throttler';

@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
  ) {}

  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('create-order')
  @UseGuards(CustomerJwtGuard)
  createOrder(
    @Req() req,
    @Body() dto: CreateCheckoutPaymentDto,
  ) {
    return this.paymentsService.createCheckoutPayment(
      req.user.customerId,
      dto,
    );
  }

  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('verify')
  @UseGuards(CustomerJwtGuard)
  verifyPayment(
    @Req() req,
    @Body() dto: VerifyPaymentDto,
  ) {
    return this.paymentsService.verifyPayment(
      req.user.customerId,
      dto,
    );
  }

  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('refund/:orderId')
  @UseGuards(AdminGuard)
  refund(@Param('orderId') orderId: string) {
    return this.paymentsService.refund(orderId);
  }

@Post('webhook')
webhook(@Req() req, @Body() body: any) {
  const signature = req.headers['x-webhook-signature'] as string;
  const timestamp = req.headers['x-webhook-timestamp'] as string;

  return this.paymentsService.webhook(
    body,
    signature,
    timestamp,
    req.rawBody,
  );
}
    @Throttle({ default: { limit: 5, ttl: 60000 } })
    @Post('reconcile')
  @UseGuards(CustomerJwtGuard)
  reconcile(
    @Req() req,
    @Body() body: ReconcilePaymentDto,
  ) {
    return this.paymentsService.reconcilePayment(
      req.user.customerId,
      body.cashfreeOrderId,
    );
  }
}