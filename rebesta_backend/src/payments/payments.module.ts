import { Module } from '@nestjs/common';

import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { CouponsModule } from '../coupons/coupons.module';
import { SocketModule } from '../socket/socket.module';
import { FcmModule } from '../fcm/fcm.module';
import { MapsModule } from '../maps/maps.module';

@Module({
  imports: [
    SocketModule,
    FcmModule,
    MapsModule,
    CouponsModule,
  ],
  controllers: [
    PaymentsController,
  ],
  providers: [
    PaymentsService,
  ],

  exports: [
    PaymentsService,
  ]
})
export class PaymentsModule {}