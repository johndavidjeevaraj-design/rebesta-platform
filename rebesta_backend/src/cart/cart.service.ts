import { Injectable } from '@nestjs/common';
import { supabase } from '../supabase';
import { MapsService } from '../maps/maps.service';
import { AddCartItemDto } from './dto/add-cart-item.dto';


@Injectable()
export class CartService {
  constructor(private readonly mapsService: MapsService) {}


  // Add item to cart
// ============================================================
// ADD ITEM TO CART
// ============================================================

async addToCart(
  customerId: string,
  dto: AddCartItemDto,
) {
  console.log('================================');
  console.log('🛒 ADD TO CART');
  console.log('Customer ID:', customerId);
  console.log('DTO:', dto);
  console.log('Menu Item ID:', dto.menuItemId);
  console.log('================================');

  // ============================================================
  // 1. FIND MENU ITEM
  // ============================================================

  const {
    data: menuItem,
    error: menuError,
  } = await supabase
    .from('menu_items')
    .select('*')
    .eq('id', dto.menuItemId)
    .maybeSingle();

  console.log('MENU LOOKUP RESULT:', menuItem);
  console.log('MENU LOOKUP ERROR:', menuError);

  if (menuError) {
    throw new Error(
      `Menu lookup failed: ${menuError.message}`,
    );
  }

  if (!menuItem) {
    throw new Error(
      `Menu item not found for ID: ${dto.menuItemId}`,
    );
  }

  if (!menuItem.is_available) {
    throw new Error(
      'This menu item is currently unavailable',
    );
  }

  console.log(
    '✅ MENU ITEM FOUND:',
    menuItem.name,
  );

  console.log(
    '🏪 RESTAURANT PARTNER:',
    menuItem.restaurant_partner_id,
  );

  // ============================================================
  // 2. FIND CART FOR THIS CUSTOMER + THIS RESTAURANT
  // ============================================================

  console.log(
    '🔎 LOOKING FOR CUSTOMER CART...',
  );

  const {
    data: carts,
    error: cartLookupError,
  } = await supabase
    .from('carts')
    .select('*')
    .eq('customer_id', customerId)
    .eq(
      'restaurant_partner_id',
      menuItem.restaurant_partner_id,
    )
    .order('created_at', {
      ascending: false,
    })
    .limit(1);

  console.log(
    'CUSTOMER CART:',
    carts,
  );

  console.log(
    'CUSTOMER CART ERROR:',
    cartLookupError,
  );

  if (cartLookupError) {
    throw new Error(
      `Cart lookup failed: ${cartLookupError.message}`,
    );
  }

  // ============================================================
  // 3. GET EXISTING CART
  // ============================================================

  let cart =
    carts && carts.length > 0
      ? carts[0]
      : null;

  // ============================================================
  // 4. CREATE CART IF IT DOESN'T EXIST
  // ============================================================

  if (!cart) {
    console.log(
      '🆕 NO CART FOUND — CREATING CART',
    );

    const {
      data: newCart,
      error: createCartError,
    } = await supabase
      .from('carts')
      .insert({
        customer_id: customerId,
        restaurant_partner_id:
          menuItem.restaurant_partner_id,
      })
      .select()
      .single();

    if (createCartError) {
      throw new Error(
        `Cart creation failed: ${createCartError.message}`,
      );
    }

    cart = newCart;

    console.log(
      '✅ NEW CART CREATED:',
      cart.id,
    );
  } else {
    console.log(
      '✅ EXISTING CART FOUND:',
      cart.id,
    );
  }

  // ============================================================
  // 5. CHECK IF ITEM ALREADY EXISTS
  // ============================================================

  const {
    data: existingItem,
    error: existingItemError,
  } = await supabase
    .from('cart_items')
    .select('*')
    .eq('cart_id', cart.id)
    .eq('menu_item_id', dto.menuItemId)
    .maybeSingle();

  if (existingItemError) {
    throw new Error(
      `Cart item lookup failed: ${existingItemError.message}`,
    );
  }

  // ============================================================
  // 6. UPDATE EXISTING ITEM
  // ============================================================

  if (existingItem) {
    console.log(
      '🔄 ITEM ALREADY IN CART',
    );

    const newQuantity =
      Number(existingItem.quantity) +
      Number(dto.quantity);

    const {
      data,
      error,
    } = await supabase
      .from('cart_items')
      .update({
        quantity: newQuantity,
      })
      .eq('id', existingItem.id)
      .select()
      .single();

    if (error) {
      throw new Error(
        `Cart item update failed: ${error.message}`,
      );
    }

    console.log(
      '✅ CART ITEM UPDATED:',
      data,
    );

    return {
      success: true,
      message: 'Cart updated',
      item: data,
    };
  }

  // ============================================================
  // 7. ADD NEW ITEM
  // ============================================================

  console.log(
    '➕ ADDING NEW ITEM TO CART',
  );

 const {
  data,
  error,
} = await supabase
  .from('cart_items')
  .insert({
    cart_id: cart.id,
    menu_item_id: dto.menuItemId,
    quantity: dto.quantity,
    price: menuItem.price,
  })
  .select()
  .single();

  if (error) {
    throw new Error(
      `Cart item creation failed: ${error.message}`,
    );
  }

  console.log(
    '✅ ITEM ADDED:',
    data,
  );

  return {
    success: true,
    message: 'Item added to cart',
    item: data,
  };
}





  // Get customer cart
  // ============================================================
// GET CUSTOMER CART
// ============================================================

// ============================================================
// GET CUSTOMER CART
// ============================================================

// ============================================================
// GET CUSTOMER CART
// ============================================================

// ============================================================
// GET CUSTOMER CART
// ============================================================

// ============================================================
// GET CUSTOMER CART
// ============================================================

async getCart(
  customerId: string,
  restaurantPartnerId?: string,
  addressId? : string,
) {
  console.log('================================');
  console.log('🛒 GET CART');
  console.log('Customer ID:', customerId);
  console.log(
    'Restaurant Partner ID:',
    restaurantPartnerId ?? 'ALL',
  );
  console.log('================================');

  // ============================================================
  // BUILD CART QUERY
  // ============================================================

  let query = supabase
    .from('carts')
    .select(`
      id,
      restaurant_partner_id,

      cart_items (
        id,
        quantity,
        price,

        menu_items (
          id,
          name,
          description,
          image_url,
          price,
          is_veg
        )
      )
    `)
    .eq(
      'customer_id',
      customerId,
    );

  // ============================================================
  // FILTER BY RESTAURANT
  // ============================================================

  if (restaurantPartnerId) {
    query = query.eq(
      'restaurant_partner_id',
      restaurantPartnerId,
    );
  }

  // ============================================================
  // GET NEWEST CART
  // ============================================================

  const {
    data: carts,
    error,
  } = await query
    .order('created_at', {
      ascending: false,
    })
    .limit(1);

  // ============================================================
  // DATABASE ERROR
  // ============================================================

  if (error) {
    console.error(
      '❌ GET CART ERROR:',
      error,
    );

    throw new Error(
      error.message,
    );
  }

  // ============================================================
  // NO CART
  // ============================================================

  if (!carts || carts.length === 0) {
    console.log(
      'ℹ️ NO CART FOUND',
    );

    return {
      success: true,

      cart: {
        id: null,

        restaurantPartnerId:
          restaurantPartnerId ?? null,

        items: [],

        total: 0,

        deliveryFee: 0,

        deliveryEstimate: null,

        
      },
    };
  }

  // ============================================================
  // CART
  // ============================================================

  const cart = carts[0];

  console.log(
    '✅ CART FOUND:',
    cart.id,
  );

  console.log(
    '🏪 RESTAURANT:',
    cart.restaurant_partner_id,
  );

  // ============================================================
  // CART ITEMS
  // ============================================================

  const rawItems =
    Array.isArray(cart.cart_items)
      ? cart.cart_items
      : [];

  const items = rawItems
    .map((item: any) => {
      const menuItem =
        Array.isArray(item.menu_items)
          ? item.menu_items[0]
          : item.menu_items;

      if (!menuItem) {
        return null;
      }

      return {
        id: item.id,

        quantity:
          Number(item.quantity ?? 0),

        price:
          Number(item.price ?? 0),

        subtotal:
          Number(item.price ?? 0) *
          Number(item.quantity ?? 0),

        menuItem: {
          id:
            menuItem.id,

          name:
            menuItem.name,

          description:
            menuItem.description,

          imageUrl:
            menuItem.image_url,

          isVeg:
            menuItem.is_veg,
        },
      };
    })
    .filter(
      (item) => item != null,
    );

  // ============================================================
  // TOTAL
  // ============================================================

  const total = items.reduce(
    (sum, item) =>
      sum +
      Number(
        item!.subtotal ?? 0,
      ),
    0,
  );
  
  // ============================================================
// DELIVERY FEE ESTIMATE (when an address is selected)
// ============================================================

let deliveryFee = 0;
let deliveryEstimate: any = null;

if (addressId) {
  const { data: address } = await supabase
    .from('addresses')
    .select('latitude, longitude')
    .eq('id', addressId)
    .eq('user_id', customerId)
    .maybeSingle();

  const { data: restaurant } = await supabase
    .from('restaurants')
    .select('latitude, longitude')
    .eq(
      'restaurant_partner_id',
      cart.restaurant_partner_id,
    )
    .maybeSingle();

  deliveryEstimate =
      await this.mapsService.calculateOrderDeliveryFee({
    restaurantLat:
      restaurant?.latitude != null
        ? Number(restaurant.latitude)
        : null,

    restaurantLng:
      restaurant?.longitude != null
        ? Number(restaurant.longitude)
        : null,

    addressLat:
      address?.latitude != null
        ? Number(address.latitude)
        : null,

    addressLng:
      address?.longitude != null
        ? Number(address.longitude)
        : null,

    subtotal: total,

    orderType: 'delivery',
  });

  deliveryFee = deliveryEstimate.fee;
}

  // ============================================================
  // RESPONSE
  // ============================================================

  return {
    success: true,

    cart: {
      id:
        cart.id,

      restaurantPartnerId:
        cart.restaurant_partner_id,

      items,

      total,
    },
  };
}


  // Update cart item quantity
  async updateCartItem(
    customerId: string,
    itemId: string,
    quantity: number,
  ) {


    const { data: cartItem, error: findError } =
      await supabase
        .from('cart_items')
        .select(`
          id,
          cart_id,
          carts (
            customer_id
          )
        `)
        .eq(
          'id',
          itemId,
        )
        .single();




    if (findError || !cartItem) {
      throw new Error(
        'Cart item not found',
      );
    }




    const cart =
      Array.isArray(cartItem.carts)
        ? cartItem.carts[0]
        : cartItem.carts;




    if (
      cart.customer_id !== customerId
    ) {

      throw new Error(
        'Unauthorized cart access',
      );

    }




    const { 
      data, 
      error 
    } =  await supabase
        .from('cart_items')
        .update({

          quantity,

        })
        .eq(
          'id',
          itemId,
        )
        .select()
        .single();




    if (error) {
      throw new Error(
        error.message,
      );
    }




    return {

      success: true,

      message:
        'Cart quantity updated',

      item: data,

    };

  }
async removeCartItem(
  customerId: string,
  itemId: string,
) {
  const { data: cartItem, error: findError } =
    await supabase
      .from('cart_items')
      .select(`
        id,
        cart_id,
        carts (
          customer_id
        )
      `)
      .eq('id', itemId)
      .single();

  if (findError || !cartItem) {
    throw new Error('Cart item not found');
  }

  const cart =
    Array.isArray(cartItem.carts)
      ? cartItem.carts[0]
      : cartItem.carts;

  if (!cart || cart.customer_id !== customerId) {
    throw new Error('Unauthorized cart access');
  }

  const { error } =
    await supabase
      .from('cart_items')
      .delete()
      .eq('id', itemId);

  if (error) {
    throw new Error(error.message);
  }

  return {
    success: true,
    message: 'Item removed from cart',
  };
}

}