import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class DeliveryJwtStrategy extends PassportStrategy(Strategy, 'delivery-jwt') {
  constructor() {
    const secret = process.env.JWT_SECRET;
    if (!secret || secret.length < 32) {
      throw new Error('JWT_SECRET must be configured with at least 32 characters');
    }
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  async validate(payload: any) {
    if (payload?.role !== 'delivery' || !payload?.sub || payload.deliveryPartnerId !== payload.sub) {
      throw new UnauthorizedException('Invalid delivery token');
    }
    return { deliveryPartnerId: payload.sub, email: payload.email, role: payload.role };
  }
}
