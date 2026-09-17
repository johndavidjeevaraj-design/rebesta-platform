import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
} from '@nestjs/common';

import { BannersService } from './banners.service';

import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';

@Controller('banners')
export class BannersController {
  constructor(
    private readonly bannersService: BannersService,
  ) {}

  // ==========================
  // Customer - Active Banners
  // ==========================

  @Get()
  getActiveBanners() {
    return this.bannersService.getActiveBanners();
  }

  // ==========================
  // Admin - Get All
  // ==========================

  @Get('admin')
  getAll() {
    return this.bannersService.findAll();
  }

  // ==========================
  // Get Banner
  // ==========================

  @Get(':id')
  getOne(
    @Param('id') id: string,
  ) {
    return this.bannersService.findOne(id);
  }

  // ==========================
  // Create Banner
  // ==========================

  @Post()
  create(
    @Body() dto: CreateBannerDto,
  ) {
    return this.bannersService.create(dto);
  }

  // ==========================
  // Update Banner
  // ==========================

  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateBannerDto,
  ) {
    return this.bannersService.update(id, dto);
  }

  // ==========================
  // Delete Banner
  // ==========================

  @Delete(':id')
  remove(
    @Param('id') id: string,
  ) {
    return this.bannersService.remove(id);
  }
}