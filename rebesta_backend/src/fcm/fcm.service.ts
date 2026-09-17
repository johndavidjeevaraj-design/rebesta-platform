import {
  BadRequestException,
  Injectable,
} from '@nestjs/common';

import { supabase } from '../supabase';
import { FirebaseService } from '../firebase/firebase.service';

import { RegisterTokenDto } from './dto/register-token.dto';

@Injectable()
export class FcmService {

    constructor(
  private readonly firebaseService: FirebaseService,
) {}


  // =====================================
// Send Push To Customer
// =====================================

async sendToCustomer(
  customerId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
) {
  const { data: tokens, error } =
    await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('customer_id', customerId);

  console.log('================================');
  console.log('🔔 FCM CUSTOMER');
  console.log('Customer:', customerId);
  console.log('Token DB error:', error);
  console.log('Token count:', tokens?.length ?? 0);
  console.log('================================');

  if (error || !tokens?.length) {
    console.log(
      '⚠️ No FCM tokens registered for customer',
    );
    return;
  }

  const message = {
    notification: {
      title,
      body,
    },
    data: data ?? {},
    tokens: tokens.map((t: any) => t.token),
  };

  const response =
    await this.firebaseService.messaging
      .sendEachForMulticast(message);

  console.log('================================');
  console.log('🔥 FCM CUSTOMER RESULT');
  console.log('Success:', response.successCount);
  console.log('Failure:', response.failureCount);
  console.log('================================');
}
  // ===============================
  // Customer
  // ===============================

  async registerCustomerToken(
    customerId: string,
    dto: RegisterTokenDto,
  ) {

    const { data: existing } =
      await supabase
        .from('fcm_tokens')
        .select('id')
        .eq('customer_id', customerId)
        .eq('token', dto.token)
        .maybeSingle();

    if (existing) {

      await supabase
        .from('fcm_tokens')
        .update({

          platform: dto.platform,

          updated_at:
            new Date().toISOString(),

        })
        .eq('id', existing.id);

    } else {

      await supabase
        .from('fcm_tokens')
        .insert({

          customer_id:
            customerId,

          token:
            dto.token,

          platform:
            dto.platform,

        });

    }

    return {

      success: true,

      message:
        'FCM token registered',

    };

  }

  // ===============================
  // Restaurant
  // ===============================

  async registerPartnerToken(
    restaurantPartnerId: string,
    dto: RegisterTokenDto,
  ) {

    const { data: existing } =
      await supabase
        .from('fcm_tokens')
        .select('id')
        .eq(
          'restaurant_partner_id',
          restaurantPartnerId,
        )
        .eq('token', dto.token)
        .maybeSingle();

    if (existing) {

      await supabase
        .from('fcm_tokens')
        .update({

          platform: dto.platform,

          updated_at:
            new Date().toISOString(),

        })
        .eq('id', existing.id);

    } else {

      await supabase
        .from('fcm_tokens')
        .insert({

          restaurant_partner_id:
            restaurantPartnerId,

          token:
            dto.token,

          platform:
            dto.platform,

        });

    }

    return {

      success: true,

      message:
        'FCM token registered',

    };

  }

  // ===============================
  // Delivery
  // ===============================

  async registerDeliveryToken(
    deliveryPartnerId: string,
    dto: RegisterTokenDto,
  ) {

    const { data: existing } =
      await supabase
        .from('fcm_tokens')
        .select('id')
        .eq(
          'delivery_partner_id',
          deliveryPartnerId,
        )
        .eq('token', dto.token)
        .maybeSingle();

    if (existing) {

      await supabase
        .from('fcm_tokens')
        .update({

          platform: dto.platform,

          updated_at:
            new Date().toISOString(),

        })
        .eq('id', existing.id);

    } else {

      await supabase
        .from('fcm_tokens')
        .insert({

          delivery_partner_id:
            deliveryPartnerId,

          token:
            dto.token,

          platform:
            dto.platform,

        });

    }

    return {

      success: true,

      message:
        'FCM token registered',

    };

  }
async sendToPartner(
  restaurantPartnerId: string,
  title: string,
  body: string,
  data?: Record<string, string>,
) {

  const { data: tokens } =
    await supabase
      .from('fcm_tokens')
      .select('token')
      .eq(
        'restaurant_partner_id',
        restaurantPartnerId,
      );

  if (!tokens?.length) {
    return;
  }

  await this.firebaseService.messaging.sendEachForMulticast({

    notification: {
      title,
      body,
    },

    data: data ?? {},

    tokens: tokens.map((t: any) => t.token),

  });

}
}