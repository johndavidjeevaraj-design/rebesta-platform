import { Test, TestingModule } from '@nestjs/testing';

import { DeliveryKycService } from './delivery-kyc.service';
import { StorageService } from '../storage/storage.service';

describe('DeliveryKycService', () => {
  let service: DeliveryKycService;

  beforeEach(async () => {
    const module: TestingModule =
      await Test.createTestingModule({
        providers: [
          DeliveryKycService,
          {
            provide: StorageService,
            useValue: {},
          },
        ],
      }).compile();

    service = module.get<DeliveryKycService>(
      DeliveryKycService,
    );
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
