import {
  Injectable,
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

  async signup(
    dto: CustomerSignupDto,
  ) {


    const { data: existingCustomer } =
      await supabase
        .from('customers')
        .select('id')
        .or(
      `email.eq.${dto.email},mobile.eq.${dto.mobile}`,
        )
        .maybeSingle();



    if (existingCustomer) {

      throw new Error(
        'Email or number already registered',
      );

    }



    const hashedPassword =
      await bcrypt.hash(
        dto.password,
        10,
      );



    const { data, error } =
      await supabase
        .from('customers')
        .insert({

          name:
            dto.name,

          email:
            dto.email,

          mobile:
            dto.mobile,

          password:
            hashedPassword,

        })
        .select()
        .single();



    if (error) {

      throw new Error(
        error.message,
      );

    }



    return {

      success: true,

      customer: {

        id:
          data.id,

        name:
          data.name,

        email:
          data.email,

        mobile:
          data.mobile,

      },

    };

  }





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

      throw new Error(
        'Invalid email or password',
      );

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
  
  
  console.log(
  '2Factor key loaded:',
  !!process.env.TWO_FACTOR_API_KEY,
);
  if (!apiKey) {
    throw new Error('TWO_FACTOR_API_KEY is not configured');
  }

  const phoneNumber = mobile.startsWith('+')
    ? mobile
    : `+91${mobile}`;

  const url =
    `https://2factor.in/API/V1/${apiKey}/SMS/${phoneNumber}/AUTOGEN/OTP1`;

  const response = await firstValueFrom(
    this.httpService.get(url),
  );

  return response.data;
}
async verifyOtp(
  mobile: string,
  otp: string,
  sessionId: string,
) {
  const apiKey = process.env.TWO_FACTOR_API_KEY;

  if (!apiKey) {
    throw new Error('TWO_FACTOR_API_KEY is not configured');
  }

  if (!mobile || !otp || !sessionId) {
    throw new Error(
      'Mobile, OTP and sessionId are required',
    );
  }

  // Always store mobile as 10 digits
  const cleanMobile = mobile
      .replace(/\D/g, '')
      .slice(-10);

  if (cleanMobile.length !== 10) {
    throw new Error('Invalid mobile number');
  }

  // Verify OTP with 2Factor
  const url =
      `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/${sessionId}/${otp}`;

  const response = await firstValueFrom(
    this.httpService.get(url),
  );

  const result = response.data;

  // Do not log OTP provider responses or verification data.
  
  if (
    !result ||
    result.Status !== 'Success'
  ) {
    throw new Error(
      result?.Details || 'Invalid OTP',
    );
  }

  // =====================================
  // OTP VERIFIED
  // Now check whether customer exists
  // =====================================

  const { data: customer, error } =
    await supabase
      .from('customers')
      .select('*')
      .eq('mobile', cleanMobile)
      .maybeSingle();

  if (error) {
    throw new Error(error.message);
  }

  // =====================================
  // NEW CUSTOMER
  // =====================================

  if (!customer) {
    const verificationToken = await this.jwtService.signAsync(
      {
        purpose: 'customer_profile_completion',
        mobile: cleanMobile,
      },
      {
        secret: process.env.JWT_SECRET,
        expiresIn: '5m',
      },
    );

    return {
      success: true,
      verified: true,
      isNewCustomer: true,
      mobile: cleanMobile,
      verificationToken,
    };
  }

  // =====================================
  // EXISTING CUSTOMER
  // =====================================

  const payload = {
    sub: customer.id,
    customerId: customer.id,
    email: customer.email,
    role: 'customer',
  };

  const token =
    await this.jwtService.signAsync(payload);

  return {
    success: true,
    verified: true,
    isNewCustomer: false,
    token,
    customer: {
      id: customer.id,
      name: customer.name,
      email: customer.email,
      mobile: customer.mobile,
    },
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
    throw new Error(error.message);
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