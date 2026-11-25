import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
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
    if (payload?.role !== 'partner' || !payload?.sub || !payload?.restaurantPartnerId) {
      throw new UnauthorizedException('Invalid partner token');
    }
    return {
      id: payload.sub,
      restaurantPartnerId: payload.restaurantPartnerId,
      email: payload.email,
      role: payload.role,
    };
  }
}
