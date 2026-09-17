import {
  Injectable,
  BadRequestException,
} from '@nestjs/common';

import { supabase } from '../supabase';

@Injectable()
export class WalletService {

  // =====================================
  // Get Wallet
  // =====================================

  async getWallet(
    customerId: string,
  ) {

    let { data: wallet } =
      await supabase
        .from('customer_wallets')
        .select('*')
        .eq('customer_id', customerId)
        .single();

    // Auto create wallet

    if (!wallet) {

      const { data } =
        await supabase
          .from('customer_wallets')
          .insert({

            customer_id:
              customerId,

          })
          .select()
          .single();

      wallet = data;

    }

    return {

      success: true,

      wallet,

    };

  }

  // =====================================
// Wallet History
// =====================================

async history(
  customerId: string,
) {

  const { data, error } =
    await supabase
      .from('wallet_transactions')
      .select('*')
      .eq(
        'customer_id',
        customerId,
      )
      .order(
        'created_at',
        {
          ascending: false,
        },
      );

  if (error) {

    throw new BadRequestException(
      error.message,
    );

  }

  return {

    success: true,

    transactions: data,

  };

}

}