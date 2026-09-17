
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { DeliveryAuthService } from './delivery-auth.service';

describe('DeliveryAuthService', () => {
  let service: DeliveryAuthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DeliveryAuthService,
        {
          provide: JwtService,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<DeliveryAuthService>(DeliveryAuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
