import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';

import { PartnerAuthController } from './partner-auth.controller';
import { PartnerAuthService } from './partner-auth.service';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    PassportModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: {
        expiresIn: '7d',
      },
    }),
  ],
  controllers: [PartnerAuthController],
  providers: [
    PartnerAuthService,
    JwtStrategy,
  ],
  exports: [
    PartnerAuthService,
  ],
})
export class PartnerAuthModule {}