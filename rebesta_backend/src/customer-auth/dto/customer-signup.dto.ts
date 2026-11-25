import { IsEmail, IsMobilePhone, IsString, MinLength, MaxLength } from 'class-validator';

export class CustomerSignupDto {
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  name!: string;

  @IsEmail()
  @MaxLength(254)
  email!: string;

  @IsMobilePhone('en-IN')
  mobile!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password!: string;
}
