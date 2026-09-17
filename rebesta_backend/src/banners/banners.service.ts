import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';

import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';

@Injectable()
export class BannersService {

  // ==========================
  // Create Banner
  // ==========================
  async create(dto: CreateBannerDto) {

    const { data, error } =
      await supabase
        .from('banners')
        .insert({

          title: dto.title,

          subtitle: dto.subtitle,

          image_url: dto.imageUrl,

          action_type: dto.actionType ?? 'none',

          action_value: dto.actionValue,

          position: dto.position ?? 1,

          is_active: dto.isActive ?? true,

        })
        .select()
        .single();

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,
      banner: data,
    };
  }

  // ==========================
  // Admin - Get All Banners
  // ==========================
  async findAll() {

    const { data, error } =
      await supabase
        .from('banners')
        .select('*')
        .order('position');

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,
      banners: data,
    };
  }

  // ==========================
  // Customer - Active Banners
  // ==========================
  async getActiveBanners() {

    const now =
      new Date().toISOString();

    const { data, error } =
      await supabase
        .from('banners')
        .select('*')
        .eq('is_active', true)
        .or(
          `start_date.is.null,start_date.lte.${now}`,
        )
        .or(
          `end_date.is.null,end_date.gte.${now}`,
        )
        .order('position');

    if (error) {
      throw new Error(error.message);
    }

    return {

      success: true,

      banners: data,

    };
  }

  // ==========================
  // Get Banner
  // ==========================
  async findOne(id: string) {

    const { data, error } =
      await supabase
        .from('banners')
        .select('*')
        .eq('id', id)
        .single();

    if (error) {
      throw new Error(error.message);
    }

    return {

      success: true,

      banner: data,

    };
  }

  // ==========================
  // Update Banner
  // ==========================
  async update(
    id: string,
    dto: UpdateBannerDto,
  ) {

    const { data, error } =
      await supabase
        .from('banners')
        .update({

          title: dto.title,

          subtitle: dto.subtitle,

          image_url: dto.imageUrl,

          action_type: dto.actionType,

          action_value: dto.actionValue,

          position: dto.position,

          is_active: dto.isActive,

        })
        .eq('id', id)
        .select()
        .single();

    if (error) {
      throw new Error(error.message);
    }

    return {

      success: true,

      banner: data,

    };
  }

  // ==========================
  // Delete Banner
  // ==========================
  async remove(id: string) {

    const { error } =
      await supabase
        .from('banners')
        .delete()
        .eq('id', id);

    if (error) {
      throw new Error(error.message);
    }

    return {

      success: true,

      message: 'Banner deleted',

    };
  }

}