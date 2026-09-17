
import { Test, TestingModule } from '@nestjs/testing';
import { DeliveryAuthController } from './delivery-auth.controller';
import { DeliveryAuthService } from './delivery-auth.service';

describe('DeliveryAuthController', () => {
  let controller: DeliveryAuthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DeliveryAuthController],
      providers: [
        {
          provide: DeliveryAuthService,
          useValue: {
            register: jest.fn(),
            login: jest.fn(),
            profile: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<DeliveryAuthController>(DeliveryAuthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
