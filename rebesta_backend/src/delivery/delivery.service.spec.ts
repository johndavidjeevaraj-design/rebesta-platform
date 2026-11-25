
import { Test, TestingModule } from '@nestjs/testing';
import { DeliveryService, isRiderCancellationAllowed } from './delivery.service';
import { MapsService } from '../maps/maps.service';
import { SocketGateway } from '../socket/socket.gateway';
import { DispatchService } from '../dispatch/dispatch.service';

describe('DeliveryService', () => {
  let service: DeliveryService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeliveryService,
        {
          provide: MapsService,
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
      ],
    }).compile();

    service = module.get<DeliveryService>(DeliveryService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});


describe('isRiderCancellationAllowed', () => {
  it.each(['accepted_for_delivery', 'arrived_at_restaurant'])(
    'allows cancellation before pickup for %s',
    (status) => {
      expect(isRiderCancellationAllowed(status)).toBe(true);
    },
  );

  it.each([
    'picked_up',
    'out_for_delivery',
    'arrived_at_customer',
    'delivered',
    'cancelled',
    'ready',
  ])('blocks cancellation at status %s', (status) => {
    expect(isRiderCancellationAllowed(status)).toBe(false);
  });
});
