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

  if (error) {
    console.warn('FCM token lookup failed.');
    return;
  }

  if (!tokens?.length) return;

  const message = {
    notification: {
      title,
      body,
    },
    data: data ?? {},
    tokens: tokens.map((t: any) => t.token),
  };

  try {
    await this.firebaseService.messaging.sendEachForMulticast(message);
  } catch {
    // Push delivery is best-effort; don't expose provider errors or tokens.
    console.warn('FCM customer push delivery failed.');
  }
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

  const { data: tokens, error } =
    await supabase
      .from('fcm_tokens')
      .select('token')
      .eq('restaurant_partner_id', restaurantPartnerId);

  if (error || !tokens?.length) return;

  try {
    await this.firebaseService.messaging.sendEachForMulticast({
      notification: { title, body },
      data: data ?? {},
      tokens: tokens.map((t: any) => t.token),
    });
  } catch {
    // Push delivery is best-effort; don't expose provider errors or tokens.
    console.warn('FCM partner push delivery failed.');
  }

}
}