import { IsString, Length, Matches } from 'class-validator';

export class SettleDeliveryPayoutDto {
  @IsString()
  @Length(4, 120)
  @Matches(/^[A-Za-z0-9._/-]+$/)
  payoutReference: string;
}
