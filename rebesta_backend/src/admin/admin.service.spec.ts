import { isAdminCancellableOrder, isAllowedRestaurantAdminTransition } from './admin.service';

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



describe('isAllowedRestaurantAdminTransition', () => {
  it.each([
    ['pending', 'approved'],
    ['pending', 'rejected'],
    ['approved', 'blocked'],
    ['blocked', 'approved'],
  ])('allows %s -> %s', (current, next) => {
    expect(isAllowedRestaurantAdminTransition(current, next)).toBe(true);
  });

  it.each([
    ['rejected', 'approved'],
    ['approved', 'rejected'],
    ['blocked', 'rejected'],
    ['pending', 'blocked'],
    ['unknown', 'approved'],
  ])('rejects %s -> %s', (current, next) => {
    expect(isAllowedRestaurantAdminTransition(current, next)).toBe(false);
  });
});
