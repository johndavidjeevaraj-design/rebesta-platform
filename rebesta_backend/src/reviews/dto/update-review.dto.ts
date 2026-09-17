import {
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

export class UpdateReviewDto {

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  restaurantRating?: number;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  deliveryRating?: number;

  @IsOptional()
  @IsString()
  review?: string;

}