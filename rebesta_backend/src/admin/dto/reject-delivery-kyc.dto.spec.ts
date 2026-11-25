import { validate } from 'class-validator';
import { RejectDeliveryKycDto } from './reject-delivery-kyc.dto';

describe('RejectDeliveryKycDto', () => {
  it('accepts a non-empty rejection reason up to 500 characters', async () => {
    const dto = new RejectDeliveryKycDto();
    dto.reason = 'Document image is unclear';
    await expect(validate(dto)).resolves.toHaveLength(0);
  });

  it('rejects an empty reason', async () => {
    const dto = new RejectDeliveryKycDto();
    dto.reason = '';
    expect((await validate(dto)).some((error) => error.property === 'reason')).toBe(true);
  });

  it('rejects a reason longer than 500 characters', async () => {
    const dto = new RejectDeliveryKycDto();
    dto.reason = 'x'.repeat(501);
    expect((await validate(dto)).some((error) => error.property === 'reason')).toBe(true);
  });
});
