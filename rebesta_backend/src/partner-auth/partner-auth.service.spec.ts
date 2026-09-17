
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { PartnerAuthService } from './partner-auth.service';

describe('PartnerAuthService', () => {
  let service: PartnerAuthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PartnerAuthService,
        {
          provide: JwtService,
          useValue: {
            sign: jest.fn(),
            verify: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<PartnerAuthService>(PartnerAuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
