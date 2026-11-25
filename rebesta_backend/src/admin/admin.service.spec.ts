import { isAdminCancellableOrder } from './admin.service';

describe('isAdminCancellableOrder', () => {
  it.each(['pending', 'failed', 'refunded'])(
    'allows a pending order with payment status %s',
    (paymentStatus) => {
      expect(isAdminCancellableOrder('pending', paymentStatus)).toBe(true);
    },
  );

  it.each(['paid', 'refund_pending', 'captured', 'unknown'])(
    'does not allow a pending order with payment status %s',
    (paymentStatus) => {
      expect(isAdminCancellableOrder('pending', paymentStatus)).toBe(false);
    },
  );

  it.each([
    'accepted',
    'preparing',
    'ready',
    'assigned',
    'picked_up',
    'out_for_delivery',
    'delivered',
    'cancelled',
  ])('does not allow an order in state %s', (orderStatus) => {
    expect(isAdminCancellableOrder(orderStatus, 'pending')).toBe(false);
  });
});
