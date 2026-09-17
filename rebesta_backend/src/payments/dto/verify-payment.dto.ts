import { IsString, IsOptional } from 'class-validator';

export class VerifyPaymentDto {

  @IsString()
  razorpayOrderId!: string;

  @IsString()
  razorpayPaymentId!: string;

  @IsString()
  signature!: string;

  @IsOptional()
  @IsString()
  orderId?: string; // unused server-side now, kept optional for compatibility

}