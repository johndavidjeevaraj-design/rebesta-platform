import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';

import { supabase } from '../supabase';

@Injectable()
export class PartnersService {

  // ==========================
  // Get Partner Profile
  // ==========================
  async getProfile(
    restaurantPartnerId: string,
  ) {
    const { data, error } = await supabase
      .from('restaurant_partners')
      .select('*')
      .eq('id', restaurantPartnerId)
      .single();

    if (error || !data) {
      throw new NotFoundException(
        'Restaurant partner not found',
      );
    }

    return {
      success: true,
      partner: data,
    };
  }

  // ==========================
  // Update Partner Profile
  // ==========================
  async updateProfile(
    restaurantPartnerId: string,
    dto: any,
  ) {
    const { data, error } = await supabase
      .from('restaurant_partners')
      .update({
        restaurant_name: dto.restaurantName,
        owner_name: dto.ownerName,
        mobile: dto.mobile,
        address: dto.address,
        city: dto.city,
        state: dto.state,
        pincode: dto.pincode,
        cuisine: dto.cuisine,
        restaurant_type: dto.restaurantType,
        logo_url: dto.logoUrl,
        cover_image_url: dto.coverImageUrl,
      })
      .eq('id', restaurantPartnerId)
      .select()
      .single();

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    return {
      success: true,
      message: 'Restaurant profile updated successfully',
      partner: data,
    };
  }
}