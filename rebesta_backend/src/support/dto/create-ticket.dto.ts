import {
  IsString,
  IsOptional,
} from 'class-validator';

export class CreateTicketDto {

  @IsString()
  subject!: string;

  @IsString()
  message!: string;

  @IsOptional()
  @IsString()
  priority?: string;

}