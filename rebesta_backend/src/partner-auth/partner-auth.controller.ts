import {
  Body,
  Controller,
  Get,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';

import { Throttle } from '@nestjs/throttler';

import { PartnerAuthService } from './partner-auth.service';

import { PartnerSignupDto } from './dto/partner-signup.dto';
import { PartnerLoginDto } from './dto/partner-login.dto';
import { PartnerSendOtpDto } from './dto/partner-send-otp.dto';
import { PartnerVerifyOtpDto } from './dto/partner-verify-otp.dto';

import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('partner-auth')
export class PartnerAuthController {

  constructor(
    private readonly partnerAuthService: PartnerAuthService,
  ) {}

  // ============================================================
  // PARTNER SIGNUP
  // ============================================================

  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('signup')
  signup(
    @Body() dto: PartnerSignupDto,
  ) {
    return this.partnerAuthService.signup(dto);
  }

  // ============================================================
  // EMAIL + PASSWORD LOGIN
  // ============================================================

  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('login')
  login(
    @Body() dto: PartnerLoginDto,
  ) {
    return this.partnerAuthService.login(dto);
  }

  // ============================================================
  // SEND MOBILE OTP
  // ============================================================

  @Throttle({ default: { limit: 3, ttl: 60000 } })
  @Post('send-otp')
  sendOtp(
    @Body() dto: PartnerSendOtpDto,
  ) {
    return this.partnerAuthService.sendOtp(
      dto.mobile,
    );
  }

  // ============================================================
  // VERIFY MOBILE OTP
  // ============================================================

  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('verify-otp')
  verifyOtp(
    @Body() dto: PartnerVerifyOtpDto,
  ) {
    return this.partnerAuthService.verifyOtp(
      dto.mobile,
      dto.otp,
      dto.sessionId,
    );
  }

  // ============================================================
  // CURRENT LOGGED-IN PARTNER
  // ============================================================

@Get('me')
@UseGuards(JwtAuthGuard)
async getProfile(@Request() req) {

  // Authenticated profile request; avoid logging identity/token context.

  return this.partnerAuthService.getCurrentPartner(
    req.user.id,
  );

}
}