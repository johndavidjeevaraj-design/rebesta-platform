import { IsUUID, Matches } from 'class-validator';

export class VerifyDeliveryOtpDto {
  @IsUUID()
  orderId!: string;

  @Matches(/^\\d{4,8}$/, { message: 'OTP must contain 4 to 8 digits' })
  otp!: string;
}
