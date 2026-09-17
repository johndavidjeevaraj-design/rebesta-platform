import { Module } from '@nestjs/common';

import { CartController } from './cart.controller';
import { CartService } from './cart.service';
import { MapsModule } from '../maps/maps.module';

@Module({
  imports: [MapsModule],
  controllers: [CartController],
  providers: [CartService],
})
export class CartModule {}