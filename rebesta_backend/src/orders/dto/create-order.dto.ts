import {
  IsUUID,
  IsOptional,
  IsString,
  IsBoolean,
} from 'class-validator';

export class CreateOrderDto {

  @IsUUID()
  addressId!: string;

  @IsUUID()
  restaurantPartnerId!: string;

  @IsOptional()
  @IsString()
  couponCode?: string;

  @IsOptional()
  @IsBoolean()
  wallet?: boolean;
}