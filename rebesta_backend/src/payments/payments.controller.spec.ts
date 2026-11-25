import { GUARDS_METADATA } from '@nestjs/common/constants';
import { PaymentsController } from './payments.controller';
import { AdminGuard } from '../admin/admin.guard';

describe('PaymentsController refund authorization', () => {
  it('requires AdminGuard on the refund handler', () => {
    const guards = Reflect.getMetadata(
      GUARDS_METADATA,
      PaymentsController.prototype.refund,
    );

    expect(guards).toContain(AdminGuard);
  });

  it('delegates the refund order id to PaymentsService', async () => {
    const paymentsService = {
      refund: jest.fn().mockResolvedValue({ success: true }),
    };
    const controller = new PaymentsController(paymentsService as any);

    await expect(controller.refund('order-123')).resolves.toEqual({
      success: true,
    });
    expect(paymentsService.refund).toHaveBeenCalledWith('order-123');
  });
});
