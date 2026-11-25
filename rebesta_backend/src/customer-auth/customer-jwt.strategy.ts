import { Injectable, UnauthorizedException } from '@nestjs/common';

import { PassportStrategy } from '@nestjs/passport';

import {
  ExtractJwt,
  Strategy,
} from 'passport-jwt';



@Injectable()
export class CustomerJwtStrategy
extends PassportStrategy(
  Strategy,
  'customer-jwt',
) {


  constructor() {

    super({

      jwtFromRequest:
        ExtractJwt.fromAuthHeaderAsBearerToken(),

      secretOrKey: (() => {
        const secret = process.env.JWT_SECRET;
        if (!secret || secret.length < 32) {
          throw new Error('JWT_SECRET must be configured with at least 32 characters');
        }
        return secret;
      })(),
      ignoreExpiration: false,

    });

  }



  async validate(payload: any) {
    if (
      payload?.role !== 'customer' ||
      !payload?.sub ||
      payload.customerId !== payload.sub
    ) {
      throw new UnauthorizedException('Invalid customer token');
    }

    return {
      id: payload.sub,
      customerId: payload.sub,
      email: payload.email,
      role: payload.role,
    };
  }

}