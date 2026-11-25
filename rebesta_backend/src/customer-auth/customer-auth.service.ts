import {
  Injectable,
  ForbiddenException,
  BadGatewayException,
} from '@nestjs/common';

import { HttpService } from '@nestjs/axios';

import { firstValueFrom } from 'rxjs';

import { supabase } from '../supabase';

import * as bcrypt from 'bcrypt';

import { JwtService } from '@nestjs/jwt';

import { CustomerSignupDto } from './dto/customer-signup.dto';
import { CustomerLoginDto } from './dto/customer-login.dto';



@Injectable()
export class CustomerAuthService {


  constructor(
    private readonly jwtService: JwtService,
    private readonly httpService: HttpService,
  ) {}



  // ===============================
  // CUSTOMER SIGNUP
  // ===============================

  async signup(_dto: CustomerSignupDto): Promise<never> {
    // Account creation must use the OTP-verified mobile flow. The legacy
    // email/password endpoint allowed registering somebody else's number.
    throw new ForbiddenException('Password signup is disabled. Use mobile OTP verification.');
  }

  // ===============================
  // CUSTOMER LOGIN

    // ===============================
  // CUSTOMER LOGIN
  // ===============================

  async login(
    dto: CustomerLoginDto,
  ) {


    const { data: customer, error } =
      await supabase
        .from('customers')
        .select('*')
        .eq(
          'email',
          dto.email,
        )
        .single();



    if (error || !customer) {

      throw new Error('Invalid email or password');

    }



    const passwordMatch =
      await bcrypt.compare(
        dto.password,
        customer.password,
      );



    if (!passwordMatch) {

      throw new Error(
        'Invalid email or password',
      );

    }



    const payload = {

      sub:
        customer.id,

      customerId:
        customer.id,

      email:
        customer.email,

      role:
        'customer',

    };



    const token =
      await this.jwtService.signAsync(
        payload,
      );



    return {

      success: true,

      token,

      customer: {

        id:
          customer.id,

        name:
          customer.name,

        email:
          customer.email,

        mobile:
          customer.mobile,

      },

    };

  }

  async sendOtp(mobile: string) {
    const apiKey = process.env.TWO_FACTOR_API_KEY;
    if (!apiKey) throw new Error('TWO_FACTOR_API_KEY is not configured');

    const cleanMobile = mobile?.replace(/\D/g, '').slice(-10);
    if (!cleanMobile || cleanMobile.length !== 10) {
      throw new Error('Invalid mobile number');
    }

    const url = `https://2factor.in/API/V1/${apiKey}/SMS/+91${cleanMobile}/AUTOGEN/OTP1`;
    let result: any;
    try {
      const response = await firstValueFrom(this.httpService.get(url));
      result = response.data;
    } catch {
      throw new BadGatewayException('Unable to send verification code. Please try again.');
    }

    if (!result || result.Status !== 'Success' || !result.Details) {
      throw new BadGatewayException('Unable to send verification code. Please try again.');
    }

    // Sign the provider session together with the destination number. A raw
    // provider session supplied by a client must never be reusable for a
    // different phone number.
    const challengeToken = await this.jwtService.signAsync(
      {
        purpose: 'customer_otp_challenge',
        mobile: cleanMobile,
        providerSessionId: result.Details,
      },
      { secret: process.env.JWT_SECRET, expiresIn: '5m' },
    );

    return { Status: 'Success', Details: challengeToken };
  }

async verifyOtp(
  mobile: string,
  otp: string,
  sessionId: string,
) {
  const apiKey = process.env.TWO_FACTOR_API_KEY;
  if (!apiKey) throw new Error('TWO_FACTOR_API_KEY is not configured');
  if (!mobile || !otp || !sessionId) {
    throw new Error('Mobile, OTP and sessionId are required');
  }

  const cleanMobile = mobile.replace(/\D/g, '').slice(-10);
  if (cleanMobile.length !== 10) throw new Error('Invalid mobile number');

  let challenge: { purpose?: string; mobile?: string; providerSessionId?: string };
  try {
    challenge = await this.jwtService.verifyAsync(sessionId, {
      secret: process.env.JWT_SECRET,
    });
  } catch {
    throw new Error('OTP session expired or invalid; request a new code');
  }

  if (
    challenge?.purpose !== 'customer_otp_challenge' ||
    challenge.mobile !== cleanMobile ||
    !challenge.providerSessionId
  ) {
    throw new Error('OTP session does not match this mobile number');
  }

  const url = `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/${encodeURIComponent(challenge.providerSessionId)}/${encodeURIComponent(otp)}`;
  let result: any;
  try {
    const response = await firstValueFrom(this.httpService.get(url));
    result = response.data;
  } catch {
    throw new BadGatewayException('OTP verification service is temporarily unavailable. Please try again.');
  }

  if (!result || result.Status !== 'Success') {
    throw new ForbiddenException('Invalid or expired OTP');
  }

  const { data: customer, error } = await supabase
    .from('customers')
    .select('id, name, email, mobile')
    .eq('mobile', cleanMobile)
    .maybeSingle();

  if (error) throw new Error('Unable to verify customer account');

  if (!customer) {
    const verificationToken = await this.jwtService.signAsync(
      { purpose: 'customer_profile_completion', mobile: cleanMobile },
      { secret: process.env.JWT_SECRET, expiresIn: '5m' },
    );
    return {
      success: true,
      verified: true,
      isNewCustomer: true,
      mobile: cleanMobile,
      verificationToken,
    };
  }

  const token = await this.jwtService.signAsync({
    sub: customer.id,
    customerId: customer.id,
    email: customer.email,
    role: 'customer',
  });

  return {
    success: true,
    verified: true,
    isNewCustomer: false,
    token,
    customer,
  };
}
  // ===============================
// CUSTOMER PROFILE
// ===============================

async profile(customerId: string) {

  const { data, error } = await supabase
      .from('customers')
      .select('id, name, email, mobile')
      .eq('id', customerId)
      .single();

  if (error) {
    throw new Error('Unable to retrieve customer profile');
  }

  return {
    success: true,
    customer: data,
  };
}

// ===============================
// UPDATE CUSTOMER PROFILE
//
// Only the name is editable: the mobile number is the
// customer's OTP login identity and must stay fixed.
// ===============================

async updateProfile(
  customerId: string,
  name: string,
) {
  const cleanName = (name ?? '').trim();

  if (cleanName.length < 2) {
    throw new Error('Please enter a valid name');
  }

  const { data, error } = await supabase
    .from('customers')
    .update({ name: cleanName })
    .eq('id', customerId)
    .select('id, name, email, mobile')
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return {
    success: true,
    customer: data,
  };
}
async completeProfile(
  mobile: string,
  name: string,
  verificationToken: string,
) {
  if (!mobile || !name || !verificationToken) {
    throw new Error('Name, mobile number and OTP verification token are required');
  }

  const cleanMobile = mobile.replace(/\D/g, '').slice(-10);
  const cleanName = name.trim();

  if (cleanMobile.length !== 10) {
    throw new Error('Invalid mobile number');
  }
  if (cleanName.length < 2 || cleanName.length > 100) {
    throw new Error('Name must be between 2 and 100 characters');
  }

  // The proof is minted only after the SMS provider confirms the OTP.
  // It is short-lived and cryptographically bound to the verified number.
  let proof: { purpose?: string; mobile?: string };
  try {
    proof = await this.jwtService.verifyAsync(verificationToken, {
      secret: process.env.JWT_SECRET,
    });
  } catch {
    throw new Error('OTP verification expired or invalid; please verify again');
  }

  if (
    proof?.purpose !== 'customer_profile_completion' ||
    proof.mobile !== cleanMobile
  ) {
    throw new Error('OTP verification does not match this mobile number');
  }

  // Never let profile completion modify or mint a token for an existing
  // account. Existing customers receive their login token from verifyOtp.
  const { data: existingCustomer, error: existingError } = await supabase
    .from('customers')
    .select('id')
    .eq('mobile', cleanMobile)
    .maybeSingle();

  if (existingError) {
    throw new Error('Unable to verify customer account status');
  }
  if (existingCustomer) {
    throw new Error('An account already exists; verify the number again to sign in');
  }

  const { data: customer, error: createError } = await supabase
    .from('customers')
    .insert({
      name: cleanName,
      mobile: cleanMobile,
      email: null,
      password: null,
    })
    .select('id, name, email, mobile')
    .single();

  if (createError || !customer) {
    // A unique mobile constraint also protects concurrent profile creation.
    throw new Error('Unable to create customer account; verify the number again');
  }

  const payload = {
    sub: customer.id,
    customerId: customer.id,
    email: customer.email ?? null,
    role: 'customer',
  };
  const token = await this.jwtService.signAsync(payload);

  return {
    success: true,
    isNewCustomer: true,
    token,
    customer: {
      id: customer.id,
      name: customer.name,
      email: customer.email,
      mobile: customer.mobile,
    },
  };
}
}