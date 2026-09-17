
import { Test, TestingModule } from '@nestjs/testing';
import { BannersController } from './banners.controller';
import { BannersService } from './banners.service';

describe('BannersController', () => {
  let controller: BannersController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [BannersController],
      providers: [
        {
          provide: BannersService,
          useValue: {
            getActiveBanners: jest.fn(),
            findAll: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            remove: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<BannersController>(BannersController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
