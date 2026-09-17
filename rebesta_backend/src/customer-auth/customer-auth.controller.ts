import {
  Controller,
  Post,
  Body,
  Get,
  Request
} from '@nestjs/common';

import { CustomerAuthService } from './customer-auth.service';
import { CustomerJwtGuard } from './customer-jwt.guard';
import { CustomerSignupDto } from './dto/customer-signup.dto';
import { CustomerLoginDto } from './dto/customer-login.dto';
import { UseGuards, Req } from '@nestjs/common';



@Controller('customer-auth')
export class CustomerAuthController {


  constructor(
    private readonly customerAuthService: CustomerAuthService,
  ) {}



  // ===============================
  // CUSTOMER SIGNUP
  // ===============================

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

@Post('send-otp')
sendOtp(
  @Body('mobile') mobile: string,
) {
  return this.customerAuthService.sendOtp(mobile);
}
@Post('verify-otp')
verifyOtp(
  @Body('mobile') mobile: string,
  @Body('otp') otp: string,
  @Body('sessionId') sessionId: string,
) {
  return this.customerAuthService.verifyOtp(
    mobile,
    otp,
    sessionId,
  );
}
@Post('complete-profile')
completeProfile(
  @Body('mobile') mobile: string,
  @Body('name') name: string,
) {
  return this.customerAuthService.completeProfile(
    mobile,
    name,
  );
}
}