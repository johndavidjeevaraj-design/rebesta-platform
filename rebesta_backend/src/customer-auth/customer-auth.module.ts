import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { JwtModule } from '@nestjs/jwt';

import { CustomerAuthController } from './customer-auth.controller';
import { CustomerAuthService } from './customer-auth.service';
import { CustomerJwtStrategy } from './customer-jwt.strategy';

@Module({
  imports: [
    HttpModule,

    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: {
        expiresIn: '7d',
      },
    }),
  ],

  controllers: [
    CustomerAuthController,
  ],

  providers: [
    CustomerAuthService,
    CustomerJwtStrategy,
  ],
})
export class CustomerAuthModule {}