import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';

import { supabase } from '../supabase';

import { CreateNotificationDto } from './dto/create-notification.dto';

@Injectable()
export class NotificationsService {

  // =====================================
  // Create Notification
  // =====================================

  async create(
    dto: CreateNotificationDto,
  ) {

    const { data, error } =
      await supabase
        .from('notifications')
        .insert({

          customer_id:
            dto.customerId,

          restaurant_partner_id:
            dto.restaurantPartnerId,

          delivery_partner_id:
            dto.deliveryPartnerId,

          title:
            dto.title,

          message:
            dto.message,

          type:
            dto.type,

          deep_link:
            dto.deepLink,

        })
        .select()
        .single();

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    return {

      success: true,

      notification: data,

    };

  }

  // =====================================
  // Customer Notifications
  // =====================================

  async getCustomerNotifications(
    customerId: string,
  ) {

    const { data, error } =
      await supabase
        .from('notifications')
        .select('*')
        .eq('customer_id', customerId)
        .order('created_at', {
          ascending: false,
        });

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    return {

      success: true,

      notifications: data,

    };

  }

  // =====================================
  // Mark Read
  // =====================================

  async markRead(
    notificationId: string,
  ) {

    const { data, error } =
      await supabase
        .from('notifications')
        .update({

          is_read: true,

        })
        .eq('id', notificationId)
        .select()
        .single();

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    return {

      success: true,

      notification: data,

    };

  }

  // =====================================
  // Delete Notification
  // =====================================

  async delete(
    notificationId: string,
  ) {

    const { error } =
      await supabase
        .from('notifications')
        .delete()
        .eq('id', notificationId);

    if (error) {
      throw new BadRequestException(
        error.message,
      );
    }

    return {

      success: true,

      message:
        'Notification deleted',

    };

  }

}