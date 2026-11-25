import { IsString, IsNotEmpty, MaxLength } from 'class-validator';

export class ReconcilePaymentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  razorpayOrderId!: string;
}
