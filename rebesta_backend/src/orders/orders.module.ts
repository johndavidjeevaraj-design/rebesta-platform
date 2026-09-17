import { Module } from '@nestjs/common';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { MapsModule } from '../maps/maps.module';
import { SocketModule } from '../socket/socket.module';
import { CouponsModule } from '../coupons/coupons.module';
import { FcmModule } from '../fcm/fcm.module';

@Module({
  imports: [
    MapsModule,
    SocketModule,
    CouponsModule,
    FcmModule
  ],

  controllers: [OrdersController],

  providers: [OrdersService],
})
export class OrdersModule {}