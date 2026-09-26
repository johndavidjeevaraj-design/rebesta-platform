import { Module } from '@nestjs/common';

import { DeliveryKycController } from './delivery-kyc.controller';
import { DeliveryKycService } from './delivery-kyc.service';
import { StorageModule } from '../storage/storage.module';

@Module({

  imports: [
    StorageModule,
  ],

  controllers: [
    DeliveryKycController,
  ],

  providers: [
    DeliveryKycService,
  ],

})
export class DeliveryKycModule {}
