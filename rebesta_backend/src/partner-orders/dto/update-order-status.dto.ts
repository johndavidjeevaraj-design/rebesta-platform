import {
  IsIn,
} from 'class-validator';

export class UpdateOrderStatusDto {

  @IsIn([
    'accepted',
    'preparing',
    'ready',
    'completed',
    'cancelled',
  ])
  status: string;

}