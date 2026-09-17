import {
  IsString,
  Matches,
} from 'class-validator';

export class PartnerVerifyOtpDto {

  @IsString()
  @Matches(/^[6-9]\d{9}$/, {
    message: 'Enter a valid 10 digit mobile number',
  })
  mobile!: string;

  @IsString()
  @Matches(/^\d{6}$/, {
    message: 'OTP must be 6 digits',
  })
  otp!: string;

  @IsString()
  sessionId!: string;
}