import {
  IsUUID,
  IsOptional,
  IsString,
  IsBoolean,
  IsIn,
} from 'class-validator';

export class CreateOrderDto {

  @IsOptional()
  @IsUUID()
  addressId?: string;

  @IsUUID()
  restaurantPartnerId!: string;

  @IsOptional()
  @IsIn(['delivery', 'pickup'])
  orderType?: 'delivery' | 'pickup';

  @IsOptional()
  @IsString()
  couponCode?: string;

  @IsOptional()
  @IsBoolean()
  wallet?: boolean;
}