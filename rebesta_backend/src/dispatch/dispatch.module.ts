import { Module } from '@nestjs/common';

import { DispatchService } from './dispatch.service';
import { SocketModule } from '../socket/socket.module';

@Module({

  imports: [
    SocketModule,
  ],

  providers: [
    DispatchService,
  ],

  exports: [
    DispatchService,
  ],

})
export class DispatchModule {}
