import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';

import { UpdateSettingsDto } from './dto/update-settings.dto';

@Injectable()
export class SettingsService {

  // ==========================
  // Get Settings
  // ==========================

  async getSettings() {

    const { data, error } =
      await supabase
        .from('settings')
        .select('*')
        .limit(1)
        .single();

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,
      settings: data,
    };
  }

  // ==========================
  // Update Settings
  // ==========================

  async updateSettings(
    dto: UpdateSettingsDto,
  ) {

    const { data: current } =
      await supabase
        .from('settings')
        .select('id')
        .limit(1)
        .single();

    if (!current) {
      throw new Error('Settings not found');
    }

    const { data, error } =
      await supabase
        .from('settings')
        .update({

          delivery_charge:
            dto.deliveryCharge,

          free_delivery_above:
            dto.freeDeliveryAbove,

          platform_commission:
            dto.platformCommission,

          gst_percentage:
            dto.gstPercentage,

          minimum_order:
            dto.minimumOrder,

          maximum_delivery_radius:
            dto.maximumDeliveryRadius,

          support_phone:
            dto.supportPhone,

          support_email:
            dto.supportEmail,

          maintenance_mode:
            dto.maintenanceMode,

          updated_at:
            new Date().toISOString(),

        })
        .eq('id', current.id)
        .select()
        .single();

    if (error) {
      throw new Error(error.message);
    }

    return {

      success: true,

      message:
        'Settings updated successfully',

      settings: data,

    };
  }
}