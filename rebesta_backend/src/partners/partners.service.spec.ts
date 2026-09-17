
import { PartnersService } from './partners.service';

describe('PartnersService', () => {
  let service: PartnersService;

  beforeEach(() => {
    service = new PartnersService();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
