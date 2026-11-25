import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class CustomerCompleteProfileDto {
  @IsString()
  @Matches(/^[6-9]\d{9}$/)
  mobile!: string;

  @IsString()
  @MinLength(2)
  @MaxLength(100)
  name!: string;

  @IsString()
  @MaxLength(4096)
  verificationToken!: string;
}
