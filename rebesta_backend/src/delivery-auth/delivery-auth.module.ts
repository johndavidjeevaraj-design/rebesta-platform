import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';

import { DeliveryAuthController } from './delivery-auth.controller';
import { DeliveryAuthService } from './delivery-auth.service';

import { DeliveryJwtStrategy } from './delivery-jwt.strategy';

@Module({
  imports: [
    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: {
        expiresIn: '30d',
      },
    }),
  ],
  controllers: [DeliveryAuthController],
  providers: [
    DeliveryAuthService,
    DeliveryJwtStrategy,
  ],
  exports: [
    JwtModule,
    DeliveryJwtStrategy,
  ],
})
export class DeliveryAuthModule {}