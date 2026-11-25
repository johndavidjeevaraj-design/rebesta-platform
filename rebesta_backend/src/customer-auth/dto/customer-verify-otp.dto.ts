import { IsString, Matches, MaxLength } from 'class-validator';

export class CustomerVerifyOtpDto {
  @IsString()
  @Matches(/^[6-9]\d{9}$/)
  mobile!: string;

  @IsString()
  @Matches(/^\d{6}$/)
  otp!: string;

  @IsString()
  @MaxLength(4096)
  sessionId!: string;
}
