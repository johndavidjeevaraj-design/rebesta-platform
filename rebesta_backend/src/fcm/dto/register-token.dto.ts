import {
  IsIn,
  IsNotEmpty,
  IsString,
} from 'class-validator';

export class RegisterTokenDto {

  @IsString()
  @IsNotEmpty()
  token: string;

  @IsString()
  @IsIn([
    'android',
    'ios',
    'web',
  ])
  platform: string;

}