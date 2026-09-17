import {
  IsEmail,
  IsNotEmpty,
} from 'class-validator';

export class LoginDeliveryDto {

  @IsEmail()
  email: string;

  @IsNotEmpty()
  password: string;

}