import {
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateBannerDto {

  @IsString()
  title!: string;

  @IsOptional()
  @IsString()
  subtitle?: string;

  @IsString()
  imageUrl!: string;

  @IsOptional()
  @IsString()
  actionType?: string;

  @IsOptional()
  @IsString()
  actionValue?: string;

  @IsOptional()
  @IsInt()
  position?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}