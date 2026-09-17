import {
  IsBoolean,
  IsEmail,
  IsNumber,
  IsOptional,
  IsString,
} from 'class-validator';

export class UpdateSettingsDto {

  @IsOptional()
  @IsNumber()
  deliveryCharge?: number;

  @IsOptional()
  @IsNumber()
  freeDeliveryAbove?: number;

  @IsOptional()
  @IsNumber()
  platformCommission?: number;

  @IsOptional()
  @IsNumber()
  gstPercentage?: number;

  @IsOptional()
  @IsNumber()
  minimumOrder?: number;

  @IsOptional()
  @IsNumber()
  maximumDeliveryRadius?: number;

  @IsOptional()
  @IsString()
  supportPhone?: string;

  @IsOptional()
  @IsEmail()
  supportEmail?: string;

  @IsOptional()
  @IsBoolean()
  maintenanceMode?: boolean;
}