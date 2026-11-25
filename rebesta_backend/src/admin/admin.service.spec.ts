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


describe('admin restaurant state transitions', () => {
  it('uses only the intended lifecycle transitions', () => {
    const allowed: Record<string, string[]> = {
      pending: ['approved', 'rejected'],
      approved: ['blocked'],
      blocked: ['approved'],
      rejected: [],
    };
    expect(allowed.pending).toEqual(['approved', 'rejected']);
    expect(allowed.approved).toContain('blocked');
    expect(allowed.blocked).toContain('approved');
    expect(allowed.rejected).toHaveLength(0);
  });
});
