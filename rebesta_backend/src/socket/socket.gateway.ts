import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
} from '@nestjs/websockets';

import { JwtService } from '@nestjs/jwt';

import { Server, Socket } from 'socket.io';

import { supabase } from '../supabase';

// ============================================================
// SOCKET GATEWAY
// ============================================================
//
// SECURITY MODEL
// --------------
// Every connection must authenticate with its JWT in the
// handshake:
//
//   auth: { token: '<accessToken>' }
//
// Unauthenticated / invalid connections are dropped in
// handleConnection, and every join handler verifies the
// requested room against the VERIFIED identity from the
// token - a customer can only join its own room, a partner
// only its own restaurant room, a rider only its own
// delivery room + the shared feed, and order rooms require
// a DB ownership check.
//
// ============================================================

@WebSocketGateway({
  cors: {
    origin: (process.env.CORS_ALLOWED_ORIGINS ?? '')
      .split(',')
      .map((origin) => origin.trim())
      .filter(Boolean),
  },
})
export class SocketGateway implements OnGatewayConnection {
  @WebSocketServer()
  server!: Server;

  constructor(private readonly jwtService: JwtService) {}

  // ==========================================================
  // HANDSHAKE AUTHENTICATION
  // ==========================================================

  async handleConnection(client: Socket) {
    const auth = client.handshake.auth ?? {};

    const bearer =
      (client.handshake.headers?.authorization ??
        '') as string;

    const token: string =
      (auth.token as string) ??
      bearer.replace('Bearer ', '');

    if (!token) {
      console.log('❌ Socket rejected: no token');

      client.disconnect(true);

      return;
    }

    try {
      const payload = await this.jwtService.verifyAsync(
        token,
        {
          secret: process.env.JWT_SECRET,
        },
      );

      // { sub, role, customerId?, restaurantPartnerId?, deliveryPartnerId? }

      client.data.user = payload;

      console.log(
        `✅ Socket authenticated: ${payload.role} ${payload.sub}`,
      );
    } catch {
      console.log('❌ Socket rejected: invalid token');

      client.disconnect(true);
    }
  }

  // ==========================================================
  // VERIFIED IDENTITY
  // ==========================================================

  identity(client: Socket) {
    return client?.data?.user as
      | {
          sub: string;
          role: string;
          restaurantPartnerId?: string;
        }
      | undefined;
  }

  // ==========================================================
  // JOIN: CUSTOMER (own room only)
  // ==========================================================

@SubscribeMessage('join_customer')
joinCustomer(
  @MessageBody() customerId: string,
  @ConnectedSocket() client: Socket,
) {
  const user = this.identity(client);

  const allowed =
    user != null &&
    user.role === 'customer' &&
    user.sub === customerId;

  if (!allowed) {
    console.log(
      `⛔ join_customer denied: ${user?.role ?? 'unauthenticated'} ${user?.sub ?? ''}`,
    );

    return {
      success: false,
      message: 'Not allowed',
    };
  }

  client.join(`customer_${customerId}`);

  console.log(
    `✅ Customer joined customer_${customerId}`,
  );

  return {
    success: true,
  };
}

// ==========================================================
// EMIT: CUSTOMER ROOM
// ==========================================================

emitToCustomer(
  customerId: string,
  event: string,
  data: any,
) {

  this.server
    .to(`customer_${customerId}`)
    .emit(event, data);

}

// ==========================================================
// JOIN: PARTNER (own restaurant room only)
// ==========================================================

@SubscribeMessage('join_partner')
joinPartner(
  @MessageBody() restaurantPartnerId: string,
  @ConnectedSocket() client: Socket,
) {
  const user = this.identity(client);

  const allowed =
    user != null &&
    user.role === 'partner' &&
    user.restaurantPartnerId === restaurantPartnerId;

  if (!allowed) {
    console.log(
      `⛔ join_partner denied: ${user?.role ?? 'unauthenticated'} ${user?.sub ?? ''}`,
    );

    return {
      success: false,
      message: 'Not allowed',
    };
  }

  client.join(
    `partner_${restaurantPartnerId}`,
  );

  console.log(
    `✅ Partner joined partner_${restaurantPartnerId}`,
  );

  return {
    success: true,
  };
}

// ==========================================================
// EMIT: PARTNER ROOM
// ==========================================================

emitToPartner(
  restaurantPartnerId: string,
  event: string,
  data: any,
) {

  this.server
    .to(`partner_${restaurantPartnerId}`)
    .emit(event, data);

}

// ==========================================================
// JOIN: DELIVERY (own room + shared feed)
// ==========================================================

@SubscribeMessage('join_delivery')
joinDelivery(
  @MessageBody() deliveryPartnerId: string,
  @ConnectedSocket() client: Socket,
) {
  const user = this.identity(client);

  const allowed =
    user != null &&
    user.role === 'delivery' &&
    user.sub === deliveryPartnerId;

  if (!allowed) {
    console.log(
      `⛔ join_delivery denied: ${user?.role ?? 'unauthenticated'} ${user?.sub ?? ''}`,
    );

    return {
      success: false,
      message: 'Not allowed',
    };
  }

  client.join(
    `delivery_${deliveryPartnerId}`,
  );

  // ==========================================================
  // Shared feed room: every AUTHENTICATED rider listens
  // here for new orders entering the delivery pool.
  // ==========================================================

  client.join('delivery_feed');

  console.log(
    `✅ Delivery joined delivery_${deliveryPartnerId}`,
  );

  return {
    success: true,
  };
}

// ==========================================================
// EMIT: DELIVERY ROOM
// ==========================================================

emitToDelivery(
  deliveryPartnerId: string,
  event: string,
  data: any,
) {

  this.server
    .to(`delivery_${deliveryPartnerId}`)
    .emit(event, data);

}

// ============================================================
// Broadcast to EVERY authenticated delivery partner.
//
// Used when an order becomes available for delivery:
// - restaurant marks the order ready
// - a rider cancels and the order returns to the pool
// ============================================================

emitToAllDelivery(
  event: string,
  data: any,
) {

  this.server
    .to('delivery_feed')
    .emit(event, data);

}

// ============================================================
// JOIN: ORDER (requires DB ownership check)
// ============================================================

@SubscribeMessage('join-order')
async joinOrder(
  @MessageBody() orderId: string,
  @ConnectedSocket() client: Socket,
) {
  const user = this.identity(client);

  if (!user) {
    return {
      success: false,
      message: 'Not allowed',
    };
  }

  const { data: order } = await supabase
    .from('orders')
    .select(
      'customer_id, restaurant_partner_id, delivery_partner_id',
    )
    .eq('id', orderId)
    .maybeSingle();

  if (!order) {
    return {
      success: false,
      message: 'Order not found',
    };
  }

  const allowed =
    (user.role === 'customer' &&
      order.customer_id === user.sub) ||
    (user.role === 'partner' &&
      order.restaurant_partner_id ===
        user.restaurantPartnerId) ||
    (user.role === 'delivery' &&
      order.delivery_partner_id === user.sub);

  if (!allowed) {
    console.log(
      `⛔ join-order denied: ${user.role} ${user.sub}`,
    );

    return {
      success: false,
      message: 'Not allowed',
    };
  }

  const room = `order_${orderId}`;

  client.join(room);

  console.log(
    `✅ Client joined ${room}`,
  );

  return {
    success: true,
  };
}

// ============================================================
// JOIN: ADMIN (requires the admin key in the handshake)
// ============================================================

@SubscribeMessage('join_admin')
joinAdmin(
  @ConnectedSocket() client: Socket,
) {
  const expected = process.env.ADMIN_API_KEY;

  const provided = client.handshake.auth?.adminKey;

  if (!expected || provided !== expected) {
    console.log('⛔ join_admin denied');

    return {
      success: false,
      message: 'Not allowed',
    };
  }

  client.join('admin');

  console.log(
    '✅ Admin connected',
  );

}

// ============================================================
// EMIT: ADMIN ROOM
// ============================================================

emitToAdmin(
  event: string,
  data: any,
) {

  this.server
    .to('admin')
    .emit(event, data);

}

// ============================================================
// RIDER LOCATION (rider role only)
// ============================================================

@SubscribeMessage('rider_location')
async handleLocation(
  @ConnectedSocket() client: Socket,
  @MessageBody() payload: { orderId?: unknown; latitude?: unknown; longitude?: unknown },
) {
  const user = this.identity(client);

  if (user == null || user.role !== 'delivery') {
    return { success: false, message: 'Not allowed' };
  }

  const orderId = payload?.orderId;
  const latitude = payload?.latitude;
  const longitude = payload?.longitude;

  if (
    typeof orderId !== 'string' ||
    orderId.length < 1 ||
    orderId.length > 128 ||
    typeof latitude !== 'number' ||
    !Number.isFinite(latitude) ||
    latitude < -90 ||
    latitude > 90 ||
    typeof longitude !== 'number' ||
    !Number.isFinite(longitude) ||
    longitude < -180 ||
    longitude > 180
  ) {
    return { success: false, message: 'Invalid location payload' };
  }

  // Only the assigned rider may update location for an active order.
  // Do not trust rider IDs or other fields supplied by the client.
  const { data: order, error } = await supabase
    .from('orders')
    .select('id, delivery_partner_id, order_status')
    .eq('id', orderId)
    .eq('delivery_partner_id', user.sub)
    .in('order_status', [
      'accepted_for_delivery',
      'arrived_at_restaurant',
      'picked_up',
      'out_for_delivery',
      'arrived_at_customer',
    ])
    .maybeSingle();

  if (error || !order) {
    return { success: false, message: 'Not allowed' };
  }

  this.server.to(`order_${order.id}`).emit('rider_location_update', {
    orderId: order.id,
    deliveryPartnerId: user.sub,
    latitude,
    longitude,
    updatedAt: new Date().toISOString(),
  });

  return { success: true };
}

// ============================================================
// EMIT: ORDER STATUS
// ============================================================

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
}
