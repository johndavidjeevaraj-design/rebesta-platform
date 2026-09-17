import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class DeliveryJwtStrategy extends PassportStrategy(
  Strategy,
  'delivery-jwt',
) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: process.env.JWT_SECRET!,
    });
  }

  async validate(payload: any) {
    return {
      deliveryPartnerId: payload.sub,
      email: payload.email,
    };
  }
}