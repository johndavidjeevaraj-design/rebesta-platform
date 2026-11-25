import { IsString, Matches } from 'class-validator';

export class CustomerSendOtpDto {
  @IsString()
  @Matches(/^[6-9]\\d{9}$/)
  mobile!: string;
}
