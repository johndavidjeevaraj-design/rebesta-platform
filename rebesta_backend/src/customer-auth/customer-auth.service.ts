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

  console.log(
    '2Factor verify response:',
    result,
  );

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
    return {
      success: true,
      verified: true,
      isNewCustomer: true,
      mobile: cleanMobile,
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
async completeProfile(
  mobile: string,
  name: string,
) {
  if (!mobile || !name) {
    throw new Error('Name and mobile number are required');
  }

  const cleanMobile = mobile
    .replace(/\D/g, '')
    .slice(-10);

  const cleanName = name.trim();

  if (cleanMobile.length !== 10) {
    throw new Error('Invalid mobile number');
  }

  if (cleanName.length < 2) {
    throw new Error('Please enter a valid name');
  }

  // ============================================================
  // CHECK EXISTING CUSTOMER
  // ============================================================

  const { data: existingCustomer, error: existingError } =
    await supabase
      .from('customers')
      .select('id, name, email, mobile')
      .eq('mobile', cleanMobile)
      .maybeSingle();

  if (existingError) {
    console.error(
      'Existing customer lookup error:',
      existingError,
    );

    throw new Error(existingError.message);
  }

  // ============================================================
  // CUSTOMER EXISTS
  // UPDATE NAME WITH THE NAME ENTERED NOW
  // ============================================================

  if (existingCustomer) {
    const { data: updatedCustomer, error: updateError } =
      await supabase
        .from('customers')
        .update({
          name: cleanName,
        })
        .eq('id', existingCustomer.id)
        .select('id, name, email, mobile')
        .single();

    if (updateError) {
      console.error(
        'UPDATE CUSTOMER ERROR:',
        updateError,
      );

      throw new Error(updateError.message);
    }

    // ==========================================================
    // CREATE JWT
    // ==========================================================

    const payload = {
      sub: updatedCustomer.id,
      customerId: updatedCustomer.id,
      email: updatedCustomer.email ?? null,
      role: 'customer',
    };

    const token =
      await this.jwtService.signAsync(payload);

    return {
      success: true,
      isNewCustomer: false,
      token,

      customer: {
        id: updatedCustomer.id,
        name: updatedCustomer.name,
        email: updatedCustomer.email,
        mobile: updatedCustomer.mobile,
      },
    };
  }

  // ============================================================
  // CREATE NEW CUSTOMER
  // ============================================================

  const { data: customer, error: createError } =
    await supabase
      .from('customers')
      .insert({
        name: cleanName,
        mobile: cleanMobile,
        email: null,
        password: null,
      })
      .select('id, name, email, mobile')
      .single();

  if (createError) {
    console.error(
      'CREATE CUSTOMER ERROR:',
      createError,
    );

    throw new Error(createError.message);
  }

  // ============================================================
  // CREATE JWT
  // ============================================================

  const payload = {
    sub: customer.id,
    customerId: customer.id,
    email: customer.email ?? null,
    role: 'customer',
  };

  const token =
    await this.jwtService.signAsync(payload);

  // ============================================================
  // RETURN NEW CUSTOMER
  // ============================================================

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