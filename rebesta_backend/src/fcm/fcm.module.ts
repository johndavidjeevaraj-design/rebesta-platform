import { Module } from '@nestjs/common';

import { FcmController } from './fcm.controller';
import { FcmService } from './fcm.service';
import { FirebaseModule } from '../firebase/firebase.module';

@Module({


    imports: [
    FirebaseModule,
  ],

  controllers: [
    FcmController,
  ],

  providers: [
    FcmService,
  ],

  exports: [
    FcmService,
  ],

})
export class FcmModule {}