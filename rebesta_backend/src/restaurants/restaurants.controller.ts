import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Req,
  UseGuards,
} from '@nestjs/common';

import { RestaurantsService } from './restaurants.service';
import { JwtAuthGuard } from '../partner-auth/jwt-auth.guard';
import { CreateRestaurantDto } from './dto/create-restaurant.dto';


@Controller('restaurants')
export class RestaurantsController {

  constructor(
    private readonly restaurantsService: RestaurantsService,
  ) {}



  // ===============================
  // CUSTOMER: GET ALL RESTAURANTS
  // ===============================

  @Get()
  findAll() {

    return this.restaurantsService.findAll();

  }




  // ===============================
  // CUSTOMER: GET SINGLE RESTAURANT
  // ===============================

  @Get(':id')
  findOne(
    @Param('id') id: string,
  ) {

    return this.restaurantsService.findOne(
      id,
    );

  }




  // ===============================
  // CUSTOMER: GET RESTAURANT MENU
  // ===============================

  @Get(':id/menu')
  getRestaurantMenu(
    @Param('id') id: string,
  ) {

    return this.restaurantsService.getRestaurantMenu(
      id,
    );

  }




  // ===============================
  // PARTNER: CREATE RESTAURANT
  // ===============================

  @Post()
  @UseGuards(JwtAuthGuard)
  createRestaurant(
    @Req() req,
    @Body() dto: CreateRestaurantDto,
  ) {

    return this.restaurantsService.createRestaurant(
      req.user.restaurantPartnerId,
      dto,
    );

  }

}