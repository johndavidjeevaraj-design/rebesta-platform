import {
  Injectable,
  UnauthorizedException,
  ConflictException,
} from '@nestjs/common';

import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

import { supabase } from '../supabase';

import { RegisterDeliveryDto } from './dto/register-delivery.dto';
import { LoginDeliveryDto } from './dto/login-delivery.dto';

@Injectable()
export class DeliveryAuthService {
  constructor(
    private readonly jwtService: JwtService,
  ) {}

  // ===============================
  // Register
  // ===============================
  async register(
    dto: RegisterDeliveryDto,
  ) {
    const { data: existing } =
      await supabase
        .from('delivery_partners')
        .select('id')
        .eq('email', dto.email)
        .maybeSingle();

    if (existing) {
      throw new ConflictException(
        'Email already registered',
      );
    }

    const hashedPassword =
      await bcrypt.hash(dto.password, 10);

    const { data, error } =
      await supabase
        .from('delivery_partners')
        .insert({
          name: dto.name,
          email: dto.email,
          mobile: dto.mobile,
          password: hashedPassword,
          vehicle_type: dto.vehicleType,
          vehicle_number: dto.vehicleNumber,

           status: 'pending',

           is_online: false,

            is_available: false,
        })
        .select()
        .single();

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,
      message:
        'Delivery partner registered successfully',
      partner: {
        id: data.id,
        name: data.name,
        email: data.email,
        mobile: data.mobile,
      },
    };
  }

 // ===============================
// Login
// ===============================
async login(
  dto: LoginDeliveryDto,
) {
  const { data, error } =
    await supabase
      .from('delivery_partners')
      .select('*')
      .eq('email', dto.email)
      .maybeSingle();

  if (error || !data) {
    throw new UnauthorizedException(
      'Invalid email or password',
    );
  }

  // ===============================
  // Check Account Status
  // ===============================
  if (data.status === 'pending') {
    throw new UnauthorizedException(
      'Your account is waiting for admin approval.',
    );
  }

  if (data.status === 'rejected') {
    throw new UnauthorizedException(
      'Your account has been rejected.',
    );
  }

  if (data.status === 'blocked') {
    throw new UnauthorizedException(
      'Your account has been blocked.',
    );
  }

  // ===============================
  // Verify Password
  // ===============================
  const valid =
    await bcrypt.compare(
      dto.password,
      data.password,
    );

  if (!valid) {
    throw new UnauthorizedException(
      'Invalid email or password',
    );
  }

  // ===============================
  // Generate JWT
  // ===============================
  const accessToken =
    this.jwtService.sign({
      sub: data.id,
       deliveryPartnerId: data.id,
       email: data.email,
      role: 'delivery',
    });

  return {
    success: true,
    accessToken,
    partner: {
      id: data.id,
      name: data.name,
      email: data.email,
      mobile: data.mobile,
      status: data.status,
    },
  };
}

  // ===============================
  // Profile
  // ===============================
  async profile(
    deliveryPartnerId: string,
  ) {
    const { data, error } =
      await supabase
        .from('delivery_partners')
        .select(`
          id,
          name,
          email,
          mobile,
          vehicle_type,
          vehicle_number,
          profile_image,
          status,
          is_online,
          is_available,
          rating,
          total_deliveries
        `)
        .eq('id', deliveryPartnerId)
        .single();

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,
      partner: data,
    };
  }
  
}