import { Test, TestingModule } from '@nestjs/testing';
import { DeliveryAuthController } from './delivery-auth.controller';

describe('DeliveryAuthController', () => {
  let controller: DeliveryAuthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DeliveryAuthController],
    }).compile();

    controller = module.get<DeliveryAuthController>(DeliveryAuthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
