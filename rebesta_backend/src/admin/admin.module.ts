import { Module } from '@nestjs/common';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { StorageModule } from '../storage/storage.module';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [
    StorageModule,
    PaymentsModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}