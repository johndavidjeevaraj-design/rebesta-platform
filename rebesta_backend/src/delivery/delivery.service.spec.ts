
import { Test, TestingModule } from '@nestjs/testing';
import { DeliveryService } from './delivery.service';
import { MapsService } from '../maps/maps.service';
import { SocketGateway } from '../socket/socket.gateway';

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
      ],
    }).compile();

    service = module.get<DeliveryService>(DeliveryService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
