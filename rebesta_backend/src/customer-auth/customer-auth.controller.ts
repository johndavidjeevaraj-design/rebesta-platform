import {
  Controller,
  Post,
  Body,
  Get,
  Request
, Patch} from '@nestjs/common';

import { Throttle } from '@nestjs/throttler';

import { CustomerAuthService } from './customer-auth.service';
import { CustomerJwtGuard } from './customer-jwt.guard';
import { CustomerSignupDto } from './dto/customer-signup.dto';
import { CustomerLoginDto } from './dto/customer-login.dto';
import { CustomerSendOtpDto } from './dto/customer-send-otp.dto';
import { CustomerVerifyOtpDto } from './dto/customer-verify-otp.dto';
import { CustomerUpdateProfileDto } from './dto/customer-update-profile.dto';
import { CustomerCompleteProfileDto } from './dto/customer-complete-profile.dto';
import { UseGuards, Req } from '@nestjs/common';



@Controller('customer-auth')
export class CustomerAuthController {


  constructor(
    private readonly customerAuthService: CustomerAuthService,
  ) {}



  // ===============================
  // CUSTOMER SIGNUP
  // ===============================

  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('signup')
  signup(
    @Body() dto: CustomerSignupDto,
  ) {

    return this.customerAuthService.signup(
      dto,
    );

  }





  // ===============================
  // CUSTOMER LOGIN
  // ===============================

  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Post('login')
  login(
    @Body() dto: CustomerLoginDto,
  ) {

    return this.customerAuthService.login(
      dto,
    );

  }

  @Get('me')
@UseGuards(CustomerJwtGuard)
getMe(@Request() req) {
  return {
    success: true,
    user: req.user,
  };
}

// ===============================
// CUSTOMER PROFILE
// ===============================



// ===============================
// CUSTOMER PROFILE
// ===============================

@UseGuards(CustomerJwtGuard)
@Get('profile')
profile(@Req() req) {
  return this.customerAuthService.profile(req.user.customerId);
}

// ===============================
// UPDATE CUSTOMER PROFILE
// ===============================

@UseGuards(CustomerJwtGuard)
@Patch('profile')
updateProfile(
  @Req() req,
  @Body() dto: CustomerUpdateProfileDto,
) {
  return this.customerAuthService.updateProfile(
    req.user.customerId,
    dto.name,
  );
}

@Throttle({ default: { limit: 3, ttl: 60000 } })
@Post('send-otp')
sendOtp(
  @Body() dto: CustomerSendOtpDto,
) {
  return this.customerAuthService.sendOtp(dto.mobile);
}
@Throttle({ default: { limit: 10, ttl: 60000 } })
@Post('verify-otp')
verifyOtp(
  @Body() dto: CustomerVerifyOtpDto,
) {
  return this.customerAuthService.verifyOtp(
    dto.mobile,
    dto.otp,
    dto.sessionId,
  );
}
@Throttle({ default: { limit: 5, ttl: 60000 } })
@Post('complete-profile')
completeProfile(
  @Body() dto: CustomerCompleteProfileDto,
) {
  return this.customerAuthService.completeProfile(
    dto.mobile,
    dto.name,
    dto.verificationToken,
  );
}
}