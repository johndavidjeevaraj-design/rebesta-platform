import { Test, TestingModule } from '@nestjs/testing';
import { PartnerOrdersController } from './partner-orders.controller';

describe('PartnerOrdersController', () => {
  let controller: PartnerOrdersController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PartnerOrdersController],
    }).compile();

    controller = module.get<PartnerOrdersController>(PartnerOrdersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
