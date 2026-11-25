import { Injectable, NotFoundException } from '@nestjs/common';
import { supabase } from '../supabase';
import { UpdateStockDto } from './dto/update-stock.dto';

@Injectable()
export class InventoryService {
  async getPartnerInventory(restaurantPartnerId: string) {
    if (!restaurantPartnerId) {
      throw new NotFoundException('Restaurant partner not found');
    }

    const { data, error } = await supabase
      .from('menu_items')
      .select('id, name, category, is_available, stock_quantity')
      .eq('restaurant_partner_id', restaurantPartnerId)
      .order('name', { ascending: true });

    if (error) {
      throw new Error(`Failed to load inventory: ${error.message}`);
    }

    return {
      success: true,
      inventory: (data ?? []).map((item) => ({
        menuItemId: item.id,
        name: item.name,
        category: item.category,
        isAvailable: item.is_available,
        stockQuantity: item.stock_quantity,
        stockTracked: item.stock_quantity !== null,
      })),
    };
  }

  async updateStock(
    restaurantPartnerId: string,
    menuItemId: string,
    dto: UpdateStockDto,
  ) {
    const { data, error } = await supabase
      .from('menu_items')
      .update({ stock_quantity: dto.stockQuantity })
      .eq('id', menuItemId)
      .eq('restaurant_partner_id', restaurantPartnerId)
      .select('id, name, stock_quantity, is_available')
      .maybeSingle();

    if (error) {
      throw new Error(`Failed to update stock: ${error.message}`);
    }
    if (!data) {
      throw new NotFoundException('Menu item not found');
    }

    return {
      success: true,
      item: {
        menuItemId: data.id,
        name: data.name,
        stockQuantity: data.stock_quantity,
        isAvailable: data.is_available,
        stockTracked: true,
      },
    };
  }
}
