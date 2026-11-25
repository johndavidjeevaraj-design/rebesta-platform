import { IsString, IsNotEmpty, MaxLength } from 'class-validator';

export class VerifyPaymentDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(45)
  cashfreeOrderId!: string;
}
