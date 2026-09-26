import { Module } from '@nestjs/common';
import { PartnerOrdersController } from './partner-orders.controller';
import { PartnerOrdersService } from './partner-orders.service';
import { NotificationsModule } from '../notifications/notifications.module';
import { SocketModule } from '../socket/socket.module';
import { DispatchModule } from '../dispatch/dispatch.module';
import { FcmModule } from '../fcm/fcm.module';


@Module({
  imports: [
    NotificationsModule,
    SocketModule,
    FcmModule,
    DispatchModule,
  ],

  controllers: [
    PartnerOrdersController,
  ],

  providers: [
    PartnerOrdersService,
  ],
})
export class PartnerOrdersModule {}