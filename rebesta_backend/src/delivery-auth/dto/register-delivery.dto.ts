import {
  IsEmail,
  IsNotEmpty,
  MinLength,
} from 'class-validator';

export class RegisterDeliveryDto {

  @IsNotEmpty()
  name: string;

  @IsEmail()
  email: string;

  @IsNotEmpty()
  mobile: string;

  @MinLength(6)
  password: string;

  vehicleType: string;

  vehicleNumber: string;

}