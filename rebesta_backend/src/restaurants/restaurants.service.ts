import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';

import { CreateRestaurantDto } from './dto/create-restaurant.dto';
import { MapsService } from '../maps/maps.service';

@Injectable()
export class RestaurantsService {
  constructor(
    private readonly mapsService: MapsService,
  ) {}

  // ============================================================
  // CUSTOMER: GET ALL RESTAURANTS
  // ============================================================

  async findAll() {
    console.log('NEW RESTAURANT FIND ALL RUNNING');

    const { data, error } = await supabase
      .from('restaurants')
      .select('*');

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,

      restaurants: data.map((restaurant) => ({
        id: restaurant.id,

        restaurantPartnerId:
          restaurant.restaurant_partner_id,

        name: restaurant.name,

        description: restaurant.description,

        address: restaurant.address,

        city: restaurant.city,

        cuisine: restaurant.cuisine,

        rating: restaurant.rating,

        reviewCount: restaurant.review_count,

        deliveryTime: restaurant.delivery_time,

        deliveryFee: restaurant.delivery_fee,

        minOrder: restaurant.min_order,

        // Existing restaurant image
        imageUrl: restaurant.image_url,

        // Dedicated menu-page banner
        bannerImageUrl: restaurant.banner_image_url,

        semanticLabel: restaurant.semantic_label,

        isFavorite: restaurant.is_favorite,

        isOpen: restaurant.is_open,

        promoLabel: restaurant.promo_label,

        category: restaurant.category,

        latitude: restaurant.latitude,

        longitude: restaurant.longitude,

        restaurantType:
          restaurant.restaurant_type,

        logoUrl:
          restaurant.logo_url,

        coverImageUrl:
          restaurant.cover_image_url,
      })),
    };
  }

  // ============================================================
  // CUSTOMER: GET SINGLE RESTAURANT
  // ============================================================

  async findOne(
    id: string,
  ) {
    const { data, error } = await supabase
      .from('restaurants')
      .select('*')
      .eq(
        'id',
        id,
      )
      .single();

    if (error) {
      throw new Error(error.message);
    }

    return {
      success: true,

      restaurant: {
        id: data.id,

        name: data.name,

        description: data.description,

        address: data.address,

        city: data.city,

        cuisine: data.cuisine,

        rating: data.rating,

        reviewCount:
          data.review_count,

        deliveryTime:
          data.delivery_time,

        deliveryFee:
          data.delivery_fee,

        minOrder:
          data.min_order,

        // Existing image
        imageUrl:
          data.image_url,

        // Dedicated menu image
        bannerImageUrl:
          data.banner_image_url,

        semanticLabel:
          data.semantic_label,

        isFavorite:
          data.is_favorite,

        isOpen:
          data.is_open,

        promoLabel:
          data.promo_label,

        category:
          data.category,

        latitude:
          data.latitude,

        longitude:
          data.longitude,

        restaurantType:
          data.restaurant_type,

        logoUrl:
          data.logo_url,

        coverImageUrl:
          data.cover_image_url,

        restaurantPartnerId:
          data.restaurant_partner_id,
      },
    };
  }

  // ============================================================
  // CUSTOMER: GET RESTAURANT MENU
  // ============================================================

  async getRestaurantMenu(
    restaurantId: string,
  ) {
    console.log('================================');
    console.log('GET RESTAURANT MENU');
    console.log('Restaurant ID:', restaurantId);

    // ----------------------------------------------------------
    // 1. GET RESTAURANT PARTNER ID
    // ----------------------------------------------------------

    const {
      data: restaurant,
      error: restaurantError,
    } = await supabase
      .from('restaurants')
      .select('restaurant_partner_id')
      .eq(
        'id',
        restaurantId,
      )
      .single();

    if (restaurantError) {
      console.error(
        'Restaurant lookup error:',
        restaurantError,
      );

      throw new Error(
        restaurantError.message,
      );
    }

    console.log(
      'Restaurant partner ID:',
      restaurant?.restaurant_partner_id,
    );

    // ----------------------------------------------------------
    // 2. MAKE SURE PARTNER ID EXISTS
    // ----------------------------------------------------------

    if (!restaurant?.restaurant_partner_id) {
      console.error(
        'Restaurant has no restaurant_partner_id:',
        restaurantId,
      );

      return {
        success: true,
        menu: [],
      };
    }

    // ----------------------------------------------------------
    // 3. GET MENU ITEMS
    // ----------------------------------------------------------

    const {
      data,
      error,
    } = await supabase
      .from('menu_items')
      .select('*')
      .eq(
        'restaurant_partner_id',
        restaurant.restaurant_partner_id,
      )
      .eq(
        'is_available',
        true,
      );

    if (error) {
      console.error(
        'Menu query error:',
        error,
      );

      throw new Error(
        error.message,
      );
    }

    console.log(
      'Menu items found:',
      data?.length ?? 0,
    );

    console.log('================================');

    return {
      success: true,

      menu: (data ?? []).map((item) => ({
        id: item.id,

        category: item.category,

        name: item.name,

        description: item.description,

        price: item.price,

        imageUrl: item.image_url,

        isVeg: item.is_veg,

        isAvailable: item.is_available,

        createdAt: item.created_at,
      })),
    };
  }

  // ============================================================
  // PARTNER: CREATE RESTAURANT
  // ============================================================

  async createRestaurant(
    restaurantPartnerId: string,
    dto: CreateRestaurantDto,
  ) {
    // ----------------------------------------------------------
    // 1. BUILD FULL RESTAURANT ADDRESS
    // ----------------------------------------------------------

    const fullAddress = [
      dto.address,
      dto.city,
      dto.state,
      dto.pincode,
    ]
      .filter(Boolean)
      .join(', ')
      .trim();

    console.log(
      '================================',
    );

    console.log(
      'CREATE RESTAURANT',
    );

    console.log(
      'Restaurant:',
      dto.restaurantName,
    );

    console.log(
      'Address:',
      fullAddress,
    );

    // ----------------------------------------------------------
    // 2. AUTO-GEOCODE RESTAURANT ADDRESS
    // ----------------------------------------------------------

    let coordinates: {
      latitude: number;
      longitude: number;
    } | null = null;

    if (fullAddress) {
      console.log(
        '📍 Geocoding restaurant address...',
      );

      coordinates =
        await this.mapsService.geocodeAddress(
          `${fullAddress}, India`,
        );

      if (coordinates) {
        console.log(
          '✅ Restaurant coordinates:',
          coordinates,
        );
      } else {
        console.warn(
          '⚠️ Restaurant created without coordinates — ' +
            'geocoding failed, set manually in dashboard',
        );
      }
    } else {
      console.warn(
        '⚠️ Restaurant has no address information — ' +
          'coordinates could not be generated',
      );
    }

    // ----------------------------------------------------------
    // 3. INSERT RESTAURANT
    // ----------------------------------------------------------

    const { data, error } = await supabase
      .from('restaurants')
      .insert({
        restaurant_partner_id:
          restaurantPartnerId,

        name:
          dto.restaurantName,

        owner_name:
          dto.ownerName,

        mobile:
          dto.mobile,

        email:
          dto.email,

        address:
          dto.address,

        city:
          dto.city,

        state:
          dto.state,

        pincode:
          dto.pincode,

        cuisine:
          dto.cuisine,

        restaurant_type:
          dto.restaurantType,

        bank_name:
          dto.bankName,

        account_number:
          dto.accountNumber,

        ifsc:
          dto.ifsc,

        logo_url:
          dto.logoUrl,

        cover_image_url:
          dto.coverImageUrl,

        banner_image_url:
          dto.bannerImageUrl,

        latitude:
          coordinates?.latitude ?? null,

        longitude:
          coordinates?.longitude ?? null,
      })
      .select()
      .single();

    if (error) {
      console.error(
        '❌ Restaurant creation failed:',
        error,
      );

      throw new Error(
        error.message,
      );
    }

    console.log(
      '✅ Restaurant created:',
      data?.id,
    );

    console.log(
      'Latitude:',
      data?.latitude,
    );

    console.log(
      'Longitude:',
      data?.longitude,
    );

    console.log(
      '================================',
    );

    // ----------------------------------------------------------
    // 4. RETURN CREATED RESTAURANT
    // ----------------------------------------------------------

    return data;
  }
}