import {
  IsNumber,
  IsString,
} from 'class-validator';

export class ApplyCouponDto {

  @IsString()
  code!: string;

  @IsNumber()
  orderAmount!: number;

  @IsString()
  restaurantPartnerId!: string;

}