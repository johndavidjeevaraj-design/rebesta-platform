import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { SocketGateway } from './socket.gateway';

@Module({
  imports: [
    // Same secret as every auth module - lets the gateway
    // verify the handshake token of any role (customer /
    // partner / delivery).
    JwtModule.register({
      secret: process.env.JWT_SECRET,
    }),
  ],
  providers: [SocketGateway],
  exports: [SocketGateway],
})
export class SocketModule {}
