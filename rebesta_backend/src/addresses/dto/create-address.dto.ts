import { IsNumber, IsString, MaxLength, Min, Max } from 'class-validator';

export class CreateAddressDto {
  @IsString()
  @MaxLength(40)
  title!: string;

  @IsString()
  @MaxLength(500)
  address!: string;

  @IsNumber({ maxDecimalPlaces: 7 })
  @Min(-90)
  @Max(90)
  latitude!: number;

  @IsNumber({ maxDecimalPlaces: 7 })
  @Min(-180)
  @Max(180)
  longitude!: number;
}
