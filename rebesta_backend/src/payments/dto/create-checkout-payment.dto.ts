import {
  IsUUID,
  IsOptional,
  IsString,
  IsIn,
} from 'class-validator';

export class CreateCheckoutPaymentDto {
  @IsOptional()
  @IsUUID()
  addressId?: string;

  @IsUUID()
  restaurantPartnerId!: string;

  @IsOptional()
  @IsString()
  couponCode?: string;

  @IsOptional()
  @IsIn(['delivery', 'pickup'])
  orderType?: 'delivery' | 'pickup';
}