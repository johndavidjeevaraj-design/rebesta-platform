import { Test, TestingModule } from '@nestjs/testing';
import { PartnerOrdersService } from './partner-orders.service';

describe('PartnerOrdersService', () => {
  let service: PartnerOrdersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [PartnerOrdersService],
    }).compile();

    service = module.get<PartnerOrdersService>(PartnerOrdersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
