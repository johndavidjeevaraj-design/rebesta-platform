
import { Test, TestingModule } from '@nestjs/testing';
import { PartnerAuthController } from './partner-auth.controller';
import { PartnerAuthService } from './partner-auth.service';

describe('PartnerAuthController', () => {
  let controller: PartnerAuthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [PartnerAuthController],
      providers: [
        {
          provide: PartnerAuthService,
          useValue: {
            signup: jest.fn(),
            login: jest.fn(),
            sendOtp: jest.fn(),
            verifyOtp: jest.fn(),
            getCurrentPartner: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<PartnerAuthController>(PartnerAuthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
