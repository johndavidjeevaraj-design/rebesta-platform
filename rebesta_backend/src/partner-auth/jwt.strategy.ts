import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET!,
    });
  }

 async validate(payload: any) {
  console.log('========================================');
  console.log('PARTNER JWT VALIDATE');
  console.log('PAYLOAD:', payload);
  console.log('========================================');

  return {
    id: payload.sub,
    restaurantPartnerId: payload.restaurantPartnerId,
    email: payload.email,
    role: payload.role,
  };
}
}