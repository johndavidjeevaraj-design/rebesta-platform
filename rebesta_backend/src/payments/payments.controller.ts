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

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';

@Controller('payments')
export class PaymentsController {
  constructor(
    private readonly paymentsService: PaymentsService,
  ) {}

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

  @Post('refund/:orderId')
  refund(@Param('orderId') orderId: string) {
    return this.paymentsService.refund(orderId);
  }

@Post('webhook')
webhook(@Req() req, @Body() body: any) {
  const signature =
    req.headers['x-razorpay-signature'] as string;

  return this.paymentsService.webhook(
    body,
    signature,
    req.rawBody,
  );
}
    @Post('reconcile')
  @UseGuards(CustomerJwtGuard)
  reconcile(
    @Req() req,
    @Body() body: { razorpayOrderId: string },
  ) {
    return this.paymentsService.reconcilePayment(
      req.user.customerId,
      body.razorpayOrderId,
    );
  }
}