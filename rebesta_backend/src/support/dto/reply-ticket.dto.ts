import { IsString } from 'class-validator';

export class ReplyTicketDto {

  @IsString()
  reply!: string;

}