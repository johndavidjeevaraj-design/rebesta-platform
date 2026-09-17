import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';

import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class SocketGateway {

  @WebSocketServer()
  server!: Server;

@SubscribeMessage('join-order')
joinOrder(
  @MessageBody() orderId: string,
  @ConnectedSocket() client: Socket,
) {
  const room = `order_${orderId}`;

  client.join(room);

  console.log(
    `✅ Client joined ${room}`,
  );

  return {
    success: true,
  };
}
emitToCustomer(
  customerId: string,
  event: string,
  data: any,
) {

  this.server
    .to(`customer_${customerId}`)
    .emit(event, data);

}
@SubscribeMessage('join_partner')
joinPartner(
  @MessageBody() restaurantPartnerId: string,
  @ConnectedSocket() client: Socket,
) {

  client.join(
    `partner_${restaurantPartnerId}`,
  );

  console.log(
    `✅ Partner joined partner_${restaurantPartnerId}`,
  );

}

emitToPartner(
  restaurantPartnerId: string,
  event: string,
  data: any,
) {

  this.server
    .to(`partner_${restaurantPartnerId}`)
    .emit(event, data);

}
@SubscribeMessage('join_delivery')
joinDelivery(
  @MessageBody() deliveryPartnerId: string,
  @ConnectedSocket() client: Socket,
) {

  client.join(
    `delivery_${deliveryPartnerId}`,
  );

  console.log(
    `✅ Delivery joined delivery_${deliveryPartnerId}`,
  );

}
emitToDelivery(
  deliveryPartnerId: string,
  event: string,
  data: any,
) {

  this.server
    .to(`delivery_${deliveryPartnerId}`)
    .emit(event, data);

}

@SubscribeMessage('join_admin')
joinAdmin(
  @ConnectedSocket() client: Socket,
) {

  client.join('admin');

  console.log(
    '✅ Admin connected',
  );

}
emitToAdmin(
  event: string,
  data: any,
) {

  this.server
    .to('admin')
    .emit(event, data);

}

 sendLocation(
  orderId: string,
  data: any,
) {

  console.log('📡 Sending location to room:', orderId);
  console.log(data);

  this.server.to(orderId).emit(
    'location-update',
    data,
  );

}

sendOrderUpdate(
  orderId: string,
  status: string,
) {
  const room = `order_${orderId}`;

  console.log('====================================');
  console.log('📡 LIVE ORDER STATUS');
  console.log('Room:', room);
  console.log('Order ID:', orderId);
  console.log('Status:', status);
  console.log('====================================');

  this.server.to(room).emit(
    'order-status',
    {
      orderId,
      status,
      updatedAt: new Date().toISOString(),
    },
  );
}

@SubscribeMessage('rider_location')
handleLocation(
 client: Socket,
 payload:any
){

 console.log(payload);

 this.server
 .to(`order_${payload.orderId}`)
 .emit(
   'rider_location_update',
   payload
 );

}
@SubscribeMessage('join_customer')
joinCustomer(
  @MessageBody() customerId: string,
  @ConnectedSocket() client: Socket,
) {
  client.join(`customer_${customerId}`);

  console.log(
    `✅ Customer joined customer_${customerId}`,
  );
}
}