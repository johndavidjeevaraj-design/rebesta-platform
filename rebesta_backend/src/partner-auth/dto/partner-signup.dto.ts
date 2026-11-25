import { IsEmail, IsMobilePhone, IsNotEmpty, IsString, MinLength, MaxLength } from 'class-validator';

export class PartnerSignupDto {
  @IsString()
  @IsNotEmpty()
  restaurantPartnerId: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @IsEmail()
  @MaxLength(254)
  email: string;

  @IsMobilePhone('en-IN')
  mobile: string;

  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password: string;
}
