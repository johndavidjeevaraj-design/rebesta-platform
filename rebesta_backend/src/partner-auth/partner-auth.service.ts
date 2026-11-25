import { Injectable, ForbiddenException, BadGatewayException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PartnerSignupDto } from './dto/partner-signup.dto';
import { PartnerLoginDto } from './dto/partner-login.dto';
import { supabase } from '../supabase';
import * as bcrypt from 'bcrypt';

@Injectable()
export class PartnerAuthService {

  constructor(
    private readonly jwtService: JwtService,
  ) {}

  async signup(_dto: PartnerSignupDto): Promise<never> {
    // Public self-service signup must not accept a client-chosen restaurant ID.
    // Partner accounts will be provisioned through an authenticated admin invite.
    throw new ForbiddenException('Partner self-registration is disabled. Contact platform support for an invitation.');
  }

  async login(dto: PartnerLoginDto) {

    const { data: user } = await supabase
      .from('partner_users')
      .select('*')
      .eq('email', dto.email)
      .maybeSingle();


    if (!user) {
      return {
        success: false,
        message: 'Invalid email or password',
      };
    }


    const passwordMatch = await bcrypt.compare(
      dto.password,
      user.password,
    );


    if (!passwordMatch) {
      return {
        success: false,
        message: 'Invalid email or password',
      };
    }


    const payload = {
      sub: user.id,
      restaurantPartnerId: user.restaurant_partner_id,
      email: user.email,
      role: 'partner',
    };


    const token = this.jwtService.sign(payload);


    return {
      success: true,
      message: 'Login successful',
      access_token: token,
      partner: {
        id: user.id,
        restaurantPartnerId: user.restaurant_partner_id,
        name: user.name,
        email: user.email,
      },
    };
  }

  // ============================================================
// SEND PARTNER OTP
// ============================================================

// ============================================================
// SEND PARTNER OTP
// ============================================================

async sendOtp(mobile: string) {
  const apiKey = process.env.TWO_FACTOR_API_KEY;
  if (!apiKey) throw new Error('TWO_FACTOR_API_KEY is not configured');

  const phone = mobile?.replace(/\D/g, '').slice(-10);
  if (!phone || phone.length !== 10) throw new Error('Enter a valid 10 digit mobile number');

  const { data: user, error } = await supabase
    .from('partner_users')
    .select('id')
    .eq('mobile', phone)
    .maybeSingle();

  if (error) throw new Error('Unable to verify partner account');
  if (!user) {
    return { success: false, registered: false, message: 'No partner account found with this mobile number.' };
  }

  const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phone}/AUTOGEN/REBESTA`;
  let data: any;
  try {
    const response = await fetch(url);
    data = await response.json();
    if (!response.ok || data.Status !== 'Success' || !data.Details) {
      throw new Error('provider rejected request');
    }
  } catch {
    throw new BadGatewayException('Unable to send verification code. Please try again.');
  }

  const challengeToken = await this.jwtService.signAsync(
    { purpose: 'partner_otp_challenge', mobile: phone, providerSessionId: data.Details },
    { secret: process.env.JWT_SECRET, expiresIn: '5m' },
  );

  return {
    success: true,
    registered: true,
    message: 'OTP sent successfully',
    sessionId: challengeToken,
  };
}

async verifyOtp(
  mobile: string,
  otp: string,
  sessionId: string,
) {
  const apiKey = process.env.TWO_FACTOR_API_KEY;
  if (!apiKey) throw new Error('TWO_FACTOR_API_KEY is not configured');

  const phone = mobile?.replace(/\D/g, '').slice(-10);
  if (!phone || phone.length !== 10 || !otp || !sessionId) {
    throw new Error('Valid mobile number, OTP and session are required');
  }

  let challenge: { purpose?: string; mobile?: string; providerSessionId?: string };
  try {
    challenge = await this.jwtService.verifyAsync(sessionId, {
      secret: process.env.JWT_SECRET,
    });
  } catch {
    throw new Error('OTP session expired or invalid; request a new code');
  }

  if (
    challenge?.purpose !== 'partner_otp_challenge' ||
    challenge.mobile !== phone ||
    !challenge.providerSessionId
  ) {
    throw new Error('OTP session does not match this mobile number');
  }

  const url = `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/${encodeURIComponent(challenge.providerSessionId)}/${encodeURIComponent(otp)}`;
  let data: any;
  try {
    const response = await fetch(url);
    data = await response.json();
  } catch {
    throw new BadGatewayException('OTP verification service is temporarily unavailable. Please try again.');
  }

  if (!data || data.Status !== 'Success') {
    throw new UnauthorizedException('Invalid or expired OTP');
  }

  const { data: user, error } = await supabase
    .from('partner_users')
    .select('id, restaurant_partner_id, name, email, mobile')
    .eq('mobile', phone)
    .maybeSingle();

  if (error) throw new Error('Unable to verify partner account');
  if (!user) {
    return { success: false, registered: false, message: 'No partner account found with this mobile number.' };
  }

  const token = await this.jwtService.signAsync({
    sub: user.id,
    restaurantPartnerId: user.restaurant_partner_id,
    email: user.email,
    role: 'partner',
  });

  return {
    success: true,
    registered: true,
    message: 'Login successful',
    access_token: token,
    partner: {
      id: user.id,
      restaurantPartnerId: user.restaurant_partner_id,
      name: user.name,
      email: user.email,
      mobile: user.mobile,
    },
  };
}

async getCurrentPartner(userId: string) {
  // Profile retrieval without logging identifiers.

  const { data: user, error } = await supabase
    .from('partner_users')
    .select(`
      id,
      name,
      email,
      mobile,
      restaurant_partner_id
    `)
    .eq('id', userId)
    .maybeSingle();

  if (error) {
    console.error('PARTNER PROFILE DB ERROR:', error);

    throw new Error(
      `Failed to load partner profile: ${error.message}`,
    );
  }

  if (!user) {
    throw new Error('Partner not found');
  }

  // ------------------------------------------------------------
  // GET RESTAURANT SEPARATELY
  // ------------------------------------------------------------

  let restaurant: any = null;

  if (user.restaurant_partner_id) {
    const {
      data: restaurantData,
      error: restaurantError,
    } = await supabase
      .from('restaurant_partners')
      .select(`
        id,
        restaurant_name,
        owner_name,
        mobile,
        address,
        city,
        state,
        pincode,
        cuisine,
        restaurant_type,
        logo_url,
        cover_image_url
      `)
      .eq('id', user.restaurant_partner_id)
      .maybeSingle();

    if (restaurantError) {
      console.error(
        'RESTAURANT PROFILE DB ERROR:',
        restaurantError,
      );

      throw new Error(
        `Failed to load restaurant: ${restaurantError.message}`,
      );
    }

    restaurant = restaurantData;
  }

  // Profile data is intentionally not written to logs.

  return {
    success: true,

    partner: {
      id: user.id,
      name: user.name,
      email: user.email,
      mobile: user.mobile,

      restaurantPartnerId:
        user.restaurant_partner_id,

      restaurantName:
        restaurant?.restaurant_name ??
        'Restaurant',

      restaurant,
    },
  };
}
}