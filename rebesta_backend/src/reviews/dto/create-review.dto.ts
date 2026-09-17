import {
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  IsUUID,
} from 'class-validator';

export class CreateReviewDto {

  @IsUUID()
  orderId!: string;

  @IsInt()
  @Min(1)
  @Max(5)
  restaurantRating!: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  deliveryRating?: number;

  @IsOptional()
  @IsString()
  review?: string;

  
}