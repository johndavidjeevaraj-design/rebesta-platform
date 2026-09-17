import { IsString } from 'class-validator';

export class VerifyDeliveryOtpDto {

  @IsString()
  orderId!: string;

  @IsString()
  otp!: string;

}