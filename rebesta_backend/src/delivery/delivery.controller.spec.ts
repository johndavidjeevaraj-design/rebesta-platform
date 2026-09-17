
import { Test, TestingModule } from '@nestjs/testing';
import { DeliveryController } from './delivery.controller';
import { DeliveryService } from './delivery.service';

describe('DeliveryController', () => {
  let controller: DeliveryController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [DeliveryController],
      providers: [
        {
          provide: DeliveryService,
          useValue: {
            getAvailableOrders: jest.fn(),
            dashboard: jest.fn(),
            acceptOrder: jest.fn(),
            pickUpOrder: jest.fn(),
            outForDelivery: jest.fn(),
            updateStatus: jest.fn(),
            getMyDeliveries: jest.fn(),
            updateLocation: jest.fn(),
            verifyOtp: jest.fn(),
            wallet: jest.fn(),
            earnings: jest.fn(),
            getActiveOrders: jest.fn(),
            arriveAtRestaurant: jest.fn(),
            arriveAtCustomer: jest.fn(),
            cancelDelivery: jest.fn(),
            completeDeliveryWithoutOtp: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<DeliveryController>(DeliveryController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
