import { IsString, IsOptional, Matches, MaxLength } from 'class-validator';

export class VerifyPaymentDto {

  @IsString()
  @MaxLength(100)
  razorpayOrderId!: string;

  @IsString()
  @MaxLength(100)
  razorpayPaymentId!: string;

  @IsString()
  @Matches(/^[a-fA-F0-9]{64}$/)
  signature!: string;

  @IsOptional()
  @IsString()
  orderId?: string; // unused server-side now, kept optional for compatibility

}