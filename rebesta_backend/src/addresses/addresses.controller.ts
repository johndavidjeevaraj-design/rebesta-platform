import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import { AddressesService } from './addresses.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { AuthGuard } from '@nestjs/passport';

@Controller('addresses')
export class AddressesController {
  constructor(
    private readonly service: AddressesService,
  ) {}

  // ============================================================
  // CREATE ADDRESS
  // ============================================================

  @Post()
  @UseGuards(AuthGuard('customer-jwt'))
  create(
    @Req() req: any,
    @Body() dto: CreateAddressDto,
  ) {
      
     console.log('========== ADDRESS AUTH ==========');
  console.log('req.user:', req.user);
  console.log('customerId:', req.user?.customerId);
  console.log('sub/id:', req.user?.id);
  console.log('==================================');


    return this.service.create(
      req.user.customerId,
      dto,
    );
  }

  // ============================================================
  // GET CUSTOMER ADDRESSES
  // ============================================================

  @Get()
  @UseGuards(AuthGuard('customer-jwt'))
  find(@Req() req: any) {
    return this.service.findByUser(
      req.user.customerId,
    );
  }

  // ============================================================
  // UPDATE ADDRESS
  // ============================================================

  @Patch(':id')
  @UseGuards(AuthGuard('customer-jwt'))
  update(
    @Req() req: any,
    @Param('id') id: string,
    @Body()
    dto: {
      title: string;
      address: string;
      latitude: number;
      longitude: number;
    },
  ) {
    return this.service.update(id, dto);
  }

  // ============================================================
  // DELETE ADDRESS
  // ============================================================

  @Delete(':id')
  @UseGuards(AuthGuard('customer-jwt'))
  remove(
    @Req() req: any,
    @Param('id') id: string,
  ) {
    return this.service.remove(id);
  }
}