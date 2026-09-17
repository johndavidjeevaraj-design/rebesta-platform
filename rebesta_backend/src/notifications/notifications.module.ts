import { Module } from '@nestjs/common';
import { FirebaseModule } from '../firebase/firebase.module';
import { FcmModule } from '../fcm/fcm.module';

import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({


  imports: [
  FirebaseModule,
  FcmModule
],

  controllers: [
    NotificationsController,
  ],

  providers: [
    NotificationsService,
  ],

  exports: [
    NotificationsService,
  ],

})
export class NotificationsModule {}