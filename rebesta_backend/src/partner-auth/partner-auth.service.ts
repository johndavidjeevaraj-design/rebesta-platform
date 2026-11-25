import { Injectable } from '@nestjs/common';
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

  async signup(dto: PartnerSignupDto) {

  const email = dto.email.trim().toLowerCase();
  const mobile = dto.mobile.replace(/\D/g, '');

  if (mobile.length !== 10) {
    return {
      success: false,
      message: 'Enter a valid 10 digit mobile number',
    };
  }

  // ============================================================
  // CHECK EMAIL
  // ============================================================

  const { data: existingEmail } = await supabase
    .from('partner_users')
    .select('id')
    .eq('email', email)
    .maybeSingle();

  if (existingEmail) {
    return {
      success: false,
      message: 'Email already registered',
    };
  }

  // ============================================================
  // CHECK MOBILE
  // ============================================================

  const { data: existingMobile } = await supabase
    .from('partner_users')
    .select('id')
    .eq('mobile', mobile)
    .maybeSingle();

  if (existingMobile) {
    return {
      success: false,
      message: 'Mobile number already registered',
    };
  }

  // ============================================================
  // HASH PASSWORD
  // ============================================================

  const hashedPassword = await bcrypt.hash(
    dto.password,
    10,
  );

  // ============================================================
  // CREATE PARTNER
  // ============================================================

  const { data, error } = await supabase
    .from('partner_users')
    .insert([
      {
        restaurant_partner_id:
          dto.restaurantPartnerId,

        name: dto.name,

        email,

        mobile,

        password: hashedPassword,
      },
    ])
    .select()
    .single();

  if (error) {
    return {
      success: false,
      message: error.message,
    };
  }

  return {
    success: true,
    message: 'Partner account created successfully',

    data: {
      id: data.id,
      restaurantPartnerId:
        data.restaurant_partner_id,
      name: data.name,
      email: data.email,
      mobile: data.mobile,
    },
  };
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

  if (!apiKey) {
    throw new Error(
      'TWO_FACTOR_API_KEY is not configured',
    );
  }

  const phone = mobile.replace(/\D/g, '');

  if (phone.length !== 10) {
    throw new Error(
      'Enter a valid 10 digit mobile number',
    );
  }

  // ==========================================================
  // CHECK PARTNER ACCOUNT FIRST
  // ==========================================================

  const {
    data: user,
    error,
  } = await supabase
    .from('partner_users')
    .select(`
      id,
      restaurant_partner_id,
      name,
      email,
      mobile
    `)
    .eq('mobile', phone)
    .maybeSingle();

  if (error) {
    throw new Error(
      error.message,
    );
  }

  if (!user) {
    return {
      success: false,
      registered: false,
      message:
        'No partner account found with this mobile number.',
    };
  }

  // ==========================================================
  // SEND OTP
  // ==========================================================

  const url =
    `https://2factor.in/API/V1/${apiKey}/SMS/` +
    `${phone}/AUTOGEN/REBESTA`;

  console.log('========================================');
  // OTP dispatch telemetry excludes phone numbers and account identifiers.

  const response = await fetch(url);

  const data = await response.json();

  // Do not log provider response payloads.

  if (data.Status !== 'Success') {
    throw new Error(
      data.Details?.toString() ??
        'Failed to send OTP',
    );
  }

  return {
    success: true,
    registered: true,
    message: 'OTP sent successfully',
    sessionId: data.Details,
  };
}

// ============================================================
// VERIFY PARTNER OTP
// ============================================================

async verifyOtp(
  mobile: string,
  otp: string,
  sessionId: string,
) {
  const apiKey = process.env.TWO_FACTOR_API_KEY;

  if (!apiKey) {
    throw new Error(
      'TWO_FACTOR_API_KEY is not configured',
    );
  }

  const phone = mobile.replace(/\D/g, '');

  const url =
    `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/` +
    `${sessionId}/${otp}`;

  console.log('========================================');
  // OTP verification telemetry excludes phone numbers and session IDs.

  const response = await fetch(url);

  const data = await response.json();

  // Do not log provider response payloads.

  if (data.Status !== 'Success') {
    throw new Error(
      data.Details?.toString() ??
        'Invalid OTP',
    );
  }

  // ==========================================================
  // FIND PARTNER USER
  // ==========================================================

 const normalizedPhone = mobile.replace(/\D/g, '');

// Avoid logging raw phone numbers.

const { data: user, error } = await supabase
  .from('partner_users')
  .select(`
    id,
    restaurant_partner_id,
    name,
    email,
    mobile
  `)
  .eq('mobile', normalizedPhone)
  .maybeSingle();

if (error) {
  console.error('PARTNER LOOKUP ERROR:', error);

  throw new Error(
    `Partner lookup failed: ${error.message}`,
  );
}

if (!user) {
  return {
    success: false,
    registered: false,
    message:
      'No partner account found with this mobile number.',
  };
}

  // ==========================================================
  // CREATE JWT
  // ==========================================================

  const payload = {
    sub: user.id,
    restaurantPartnerId:
      user.restaurant_partner_id,
    email: user.email,
    role: 'partner',
  };

  const token =
    this.jwtService.sign(payload);

  return {
    success: true,
    registered: true,
    message: 'Login successful',
    access_token: token,

    partner: {
      id: user.id,
      restaurantPartnerId:
        user.restaurant_partner_id,
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