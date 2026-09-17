import {
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateNotificationDto {

  @IsOptional()
  customerId?: string;

  @IsOptional()
  restaurantPartnerId?: string;

  @IsOptional()
  deliveryPartnerId?: string;

  @IsString()
  title!: string;

  @IsString()
  message!: string;

  @IsString()
  type!: string;

  @IsOptional()
  @IsString()
  deepLink?: string;

}