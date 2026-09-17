import { Injectable } from '@nestjs/common';

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

      secretOrKey:
        process.env.JWT_SECRET!,

    });

  }



  async validate(
    payload: any) {

    console.log('================================');
  console.log('CUSTOMER JWT VALIDATED');
  console.log('PAYLOAD CUSTOMER ID:', payload.customerId);
  console.log('PAYLOAD ROLE:', payload.role);
  console.log('================================');
  

    return {

      id:
        payload.sub,

      customerId:
        payload.customerId,

      email:
        payload.email,

      role:
        payload.role,

    };

  }

}