import { Test, TestingModule } from '@nestjs/testing';
import { PartnerOrdersController } from './partner-orders.controller';
import { PartnerOrdersService } from './partner-orders.service';

describe('PartnerOrdersController', () => {
  let controller: PartnerOrdersController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PartnerOrdersController],
      providers: [
        {
          provide: PartnerOrdersService,
          useValue: {},
        },
      ],
    }).compile();

    controller = module.get<PartnerOrdersController>(PartnerOrdersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
