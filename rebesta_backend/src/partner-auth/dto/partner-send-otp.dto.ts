import {
  IsString,
  Matches,
} from 'class-validator';

export class PartnerSendOtpDto {

  @IsString()
  @Matches(/^[6-9]\d{9}$/, {
    message: 'Enter a valid 10 digit mobile number',
  })
  mobile!: string;
}