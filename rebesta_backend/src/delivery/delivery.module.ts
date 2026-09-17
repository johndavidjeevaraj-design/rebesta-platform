import { Module } from '@nestjs/common';
import { DeliveryService } from './delivery.service';
import { DeliveryController } from './delivery.controller';

import { NotificationsModule } from '../notifications/notifications.module';
import { MapsModule } from '../maps/maps.module';
import { SocketModule } from '../socket/socket.module';


@Module({

  imports: [
    NotificationsModule,
    MapsModule,
    SocketModule,
  ],

  controllers: [
    DeliveryController,
  ],

  providers: [
    DeliveryService,
  ],

  exports:[
    DeliveryService,
  ],

})
export class DeliveryModule {}