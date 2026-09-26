
import { Test, TestingModule } from '@nestjs/testing';
import { PartnerOrdersService } from './partner-orders.service';
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
