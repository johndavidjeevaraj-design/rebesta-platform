import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';
import { InventoryService } from './inventory.service';
import { UpdateStockDto } from './dto/update-stock.dto';

@Controller('inventory')
@UseGuards(JwtAuthGuard)
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get('partner')
  getPartnerInventory(@Req() req: any) {
    return this.inventoryService.getPartnerInventory(
      req.user.restaurantPartnerId,
    );
  }

  @Patch(':menuItemId/stock')
  updateStock(
    @Req() req: any,
    @Param('menuItemId') menuItemId: string,
    @Body() dto: UpdateStockDto,
  ) {
    return this.inventoryService.updateStock(
      req.user.restaurantPartnerId,
      menuItemId,
      dto,
    );
  }
}
