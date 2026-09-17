import {
  Controller,
  Post,
  Body,
  Req,
  UseGuards,
  Patch,
  Param,
  Get,
  Delete,
  Query,
} from '@nestjs/common';

import { CartService } from './cart.service';

import { AddCartItemDto } from './dto/add-cart-item.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';

@Controller('cart')
export class CartController {
  constructor(
    private readonly cartService: CartService,
  ) {}

  // ============================================================
  // ADD ITEM TO CART
  // ============================================================
  @Post('items')
  @UseGuards(CustomerJwtGuard)
  addToCart(
    @Req() req,
    @Body() dto: AddCartItemDto,
  ) {
    return this.cartService.addToCart(
      req.user.customerId,
      dto,
    );
  }

  // ============================================================
  // GET CUSTOMER CART
  // ============================================================
  @Get()
  @UseGuards(CustomerJwtGuard)
  getCart(
    @Req() req,
    @Query('restaurantPartnerId') 
    restaurantPartnerId?: string,
    @Query('addressId') addressId?: string,
  ) {
    return this.cartService.getCart(
      req.user.customerId,
      restaurantPartnerId,
      addressId,
    );
  }

  // ============================================================
  // UPDATE CART ITEM
  // ============================================================
  @Patch('items/:id')
  @UseGuards(CustomerJwtGuard)
  updateCartItem(


    
    @Req() req,
    @Param('id') id: string,
    @Body() dto: UpdateCartItemDto,
  ) {


    
    return this.cartService.updateCartItem(
      req.user.customerId,
      id,
      dto.quantity,
    );
  }

  // ============================================================
  // REMOVE CART ITEM
  // ============================================================
  @Delete('items/:id')
  @UseGuards(CustomerJwtGuard)
  removeCartItem(
    @Req() req,
    @Param('id') id: string,
  ) {
    return this.cartService.removeCartItem(
      req.user.customerId,
      id,
    );
  }
}