import {
  Body,
  Controller,
  Get,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';

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

  @Post('signup')
  signup(
    @Body() dto: PartnerSignupDto,
  ) {
    return this.partnerAuthService.signup(dto);
  }

  // ============================================================
  // EMAIL + PASSWORD LOGIN
  // ============================================================

  @Post('login')
  login(
    @Body() dto: PartnerLoginDto,
  ) {
    return this.partnerAuthService.login(dto);
  }

  // ============================================================
  // SEND MOBILE OTP
  // ============================================================

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

  console.log('========================================');
  console.log('PARTNER PROFILE REQUEST');
  console.log('REQ.USER:', req.user);
  console.log('PARTNER USER ID:', req.user.id);
  console.log('========================================');

  return this.partnerAuthService.getCurrentPartner(
    req.user.id,
  );

}
}