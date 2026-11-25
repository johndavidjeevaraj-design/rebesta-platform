import {
  IsNumber,
  IsString,
  IsNotEmpty,
  Min,
  MaxLength,
} from 'class-validator';

export class ApplyCouponDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  code!: string;

  @IsNumber({ allowNaN: false, allowInfinity: false })
  @Min(0.01)
  orderAmount!: number;

  @IsString()
  @IsNotEmpty()
  restaurantPartnerId!: string;
}
