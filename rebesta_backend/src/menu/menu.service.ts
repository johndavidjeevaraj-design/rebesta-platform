import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';

import { CreateMenuDto } from './dto/create-menu.dto';
import { UpdateMenuDto } from './dto/update-menu.dto';


@Injectable()
export class MenuService {


  // Partner: Create menu item
  async createMenu(
    restaurantPartnerId: string,
    dto: CreateMenuDto,
  ) {

    const { data, error } = await supabase
      .from('menu_items')
      .insert({

        restaurant_partner_id: restaurantPartnerId,
        category: dto.category,
        name: dto.name,
        description: dto.description,
        price: dto.price,
        image_url: dto.imageUrl,
        is_veg: dto.isVeg,
        is_available: dto.isAvailable,

      })
      .select()
      .single();


    if (error) {
      throw new Error('Menu operation failed');
    }


    return data;
  }




  // Partner: Get own restaurant menu
async getPartnerMenu(
  restaurantPartnerId: string,
) {
  if (!restaurantPartnerId) {
    throw new Error(
      'Restaurant partner ID missing from authentication token',
    );
  }

  const {
    data,
    error,
  } = await supabase
    .from('menu_items')
    .select(`
      id,
      restaurant_partner_id,
      category,
      name,
      description,
      price,
      image_url,
      is_veg,
      is_available,
      created_at
    `)
    .eq(
      'restaurant_partner_id',
      restaurantPartnerId,
    )
    .order(
      'created_at',
      { ascending: false },
    );

  if (error) {
    throw new Error('Unable to load restaurant menu');
  }

  const menu = (data ?? []).map((item) => ({
    id: item.id,
    category: item.category,
    name: item.name,
    description: item.description,
    price: item.price,
    imageUrl: item.image_url,
    isVeg: item.is_veg,
    isAvailable: item.is_available,
    createdAt: item.created_at,
  }));

  return {
    success: true,
    menu,
  };
}



  // Partner: Update menu item
  async updateMenu(
    restaurantPartnerId: string,
    id: string,
    dto: UpdateMenuDto,
  ) {

    const { data, error } = await supabase
      .from('menu_items')
      .update(Object.fromEntries(Object.entries({ category: dto.category, name: dto.name, description: dto.description, price: dto.price, image_url: dto.imageUrl, is_veg: dto.isVeg, is_available: dto.isAvailable }).filter(([, value]) => value !== undefined)))
      .eq(
        'id',
        id,
      )
      .eq(
        'restaurant_partner_id',
        restaurantPartnerId,
      )
      .select()
      .single();


    if (error) {
      throw new Error('Menu operation failed');
    }


    return data;
  }

  // Partner: Delete menu item
  async deleteMenu(
    restaurantPartnerId: string,
    id: string,
  ) {

    const { data, error } = await supabase
      .from('menu_items')
      .delete()
      .eq(
        'id',
         id,
       )
      .eq(
      'restaurant_partner_id',
      restaurantPartnerId,
      )
     .select()
     .single();


    if (error) {
      throw new Error('Menu operation failed');
    }


    return {
     success: true,
     message: 'Menu item deleted successfully',
     data,
    };
  }


 // Partner: Toggle availability
async toggleAvailability(
  restaurantPartnerId: string,
  id: string,
  isAvailable: boolean,
) {

  const { data, error } = await supabase
    .from('menu_items')
    .update({
      is_available: isAvailable,
    })
    .eq('id', id)
    .eq('restaurant_partner_id', restaurantPartnerId)
    .select();


  if (error) {
    throw new Error('Menu operation failed');
  }


  if (!data || data.length === 0) {
    throw new Error(
      'Menu item not found',
    );
  }


  return data[0];
}


  // Customer: Get all menu items
async findAll(
  category?: string,
  isVeg?: boolean,
) {
  let query = supabase
    .from('menu_items')
    .select('*')
    .eq(
      'is_available',
      true,
    );

  if (category) {
    query = query.eq(
      'category',
      category,
    );
  }

  if (isVeg === true) {
    query = query.eq(
      'is_veg',
      true,
    );
  }

  const { data, error } = await query;

  if (error) {
    throw new Error('Menu operation failed');
  }


  return {
    success: true,

    menu: data.map((item) => ({

      id: item.id,

      category: item.category,

      name: item.name,

      description: item.description,

      price: item.price,

      imageUrl: item.image_url,

      isVeg: item.is_veg,

    })),
  };
}


 // Customer: Get single menu item
async findOne(id: string) {

  const { data, error } = await supabase
    .from('menu_items')
    .select('*')
    .eq(
      'id',
      id,
    )
    .eq(
      'is_available',
      true,
    )
    .single();


  if (error) {
    throw new Error('Menu operation failed');
  }


  return {
    success: true,

    item: {

      id: data.id,

      category: data.category,

      name: data.name,

      description: data.description,

      price: data.price,

      imageUrl: data.image_url,

      isVeg: data.is_veg,

    },
  };
}

}
