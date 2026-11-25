import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';
import { CreateAddressDto } from './dto/create-address.dto';

@Injectable()
export class AddressesService {
  // ============================================================
  // CREATE ADDRESS
  // ============================================================

  async create(customerId: string, dto: CreateAddressDto) {
    const { data, error } = await supabase
      .from('addresses')
      .insert({
        ...dto,
        user_id: customerId,
      })
      .select()
      .single();

    if (error) {
      throw error;
    }

    return data;
  }

  // ============================================================
  // GET CUSTOMER ADDRESSES
  // ============================================================

  async findByUser(user_id: string) {
    const { data, error } = await supabase
      .from('addresses')
      .select('*')
      .eq('user_id', user_id);

    if (error) {
      throw error;
    }

    return data;
  }

  // ============================================================
  // UPDATE ADDRESS
  // ============================================================

  async update(
    customerId: string,
    id: string,
    dto: {
      title: string;
      address: string;
      latitude: number;
      longitude: number;
    },
  ) {
    const { data, error } = await supabase
      .from('addresses')
      .update({
        title: dto.title,
        address: dto.address,
        latitude: dto.latitude,
        longitude: dto.longitude,
      })
      .eq('id', id)
      .eq('user_id', customerId)
      .select()
      .single();

    if (error) {
      throw error;
    }

    return data;
  }

  // ============================================================
  // DELETE ADDRESS
  // ============================================================

  async remove(customerId: string, id: string) {
    const { data, error } = await supabase
      .from('addresses')
      .delete()
      .eq('id', id)
      .eq('user_id', customerId)
      .select()
      .single();

    if (error) {
      throw error;
    }

    return data;
  }
}