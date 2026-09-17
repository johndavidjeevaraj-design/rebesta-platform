import {
  Controller,
  Get,
  Req,
  UseGuards,
} from '@nestjs/common';

import { WalletService } from './wallet.service';

import { CustomerJwtGuard } from '../customer-auth/customer-jwt.guard';

@Controller('wallet')
export class WalletController {

  constructor(

    private readonly walletService: WalletService,

  ) {}

  @Get()
  @UseGuards(CustomerJwtGuard)
  wallet(
    @Req() req,
  ) {

    return this.walletService.getWallet(
      req.user.customerId,
    );

  }

  @Get('history')
  @UseGuards(CustomerJwtGuard)
  history(
    @Req() req,
  ) {

    return this.walletService.history(
      req.user.customerId,
    );

  }

}