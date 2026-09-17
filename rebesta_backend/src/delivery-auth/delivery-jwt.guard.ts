import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class DeliveryJwtGuard extends AuthGuard(
  'delivery-jwt',
) {}