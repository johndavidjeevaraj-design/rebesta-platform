import { IsEmail, IsNotEmpty, IsString, MinLength, MaxLength, Matches } from 'class-validator';

export class RegisterDeliveryDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @IsEmail()
  @MaxLength(254)
  email: string;

  @Matches(/^\\+?[0-9]{10,15}$/)
  mobile: string;

  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  vehicleType: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  vehicleNumber: string;
}
