import { IsBoolean } from 'class-validator';

export class UpdateDeliveryStatusDto {
  @IsBoolean()
  isOnline: boolean;
}