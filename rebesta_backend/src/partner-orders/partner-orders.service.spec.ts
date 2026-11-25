
import { Test, TestingModule } from '@nestjs/testing';
import { canAcceptRestaurantOrder, canCancelRestaurantOrder, PartnerOrdersService } from './partner-orders.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SocketGateway } from '../socket/socket.gateway';
import { DispatchService } from '../dispatch/dispatch.service';
import { FcmService } from '../fcm/fcm.service';

describe('PartnerOrdersService', () => {
  let service: PartnerOrdersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PartnerOrdersService,
        {
          provide: NotificationsService,
          useValue: {},
        },
        {
          provide: SocketGateway,
          useValue: {},
        },
        {
          provide: DispatchService,
          useValue: {},
        },
        {
          provide: FcmService,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<PartnerOrdersService>(PartnerOrdersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});


describe('canAcceptRestaurantOrder', () => {
  it('allows COD orders while payment is pending', () => {
    expect(canAcceptRestaurantOrder({
      order_status: 'pending',
      payment_status: 'pending',
      razorpay_order_id: null,
    })).toBe(true);
  });

  it('allows captured online orders', () => {
    expect(canAcceptRestaurantOrder({
      order_status: 'pending',
      payment_status: 'paid',
      razorpay_order_id: 'order_test_123',
    })).toBe(true);
  });

  it('rejects online orders that are not paid', () => {
    expect(canAcceptRestaurantOrder({
      order_status: 'pending',
      payment_status: 'pending',
      razorpay_order_id: 'order_test_123',
    })).toBe(false);
    expect(canAcceptRestaurantOrder({
      order_status: 'pending',
      payment_status: 'failed',
      razorpay_order_id: 'order_test_123',
    })).toBe(false);
  });

  it('does not re-check payment once the order has left pending', () => {
    expect(canAcceptRestaurantOrder({
      order_status: 'accepted',
      payment_status: 'pending',
      razorpay_order_id: 'order_test_123',
    })).toBe(true);
  });
});


describe('canCancelRestaurantOrder', () => {
  it('allows unpaid COD orders before and during preparation', () => {
    for (const order_status of ['pending', 'accepted', 'preparing']) {
      expect(canCancelRestaurantOrder({ order_status, payment_status: 'pending' })).toBe(true);
    }
  });

  it('allows failed or already-refunded orders in cancellable states', () => {
    expect(canCancelRestaurantOrder({ order_status: 'pending', payment_status: 'failed' })).toBe(true);
    expect(canCancelRestaurantOrder({ order_status: 'preparing', payment_status: 'refunded' })).toBe(true);
  });

  it('blocks paid orders until a refund is completed', () => {
    expect(canCancelRestaurantOrder({ order_status: 'pending', payment_status: 'paid' })).toBe(false);
  });

  it('blocks cancellation after preparation or dispatch has advanced', () => {
    for (const order_status of ['ready', 'assigned', 'picked_up', 'out_for_delivery', 'delivered', 'cancelled']) {
      expect(canCancelRestaurantOrder({ order_status, payment_status: 'pending' })).toBe(false);
    }
  });
});
