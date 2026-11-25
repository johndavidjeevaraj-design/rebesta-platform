import * as crypto from 'crypto';
import { cashfreeRefundPaymentStatus, isCashfreePaymentMatch, isCashfreeWebhookSignatureValid } from './payments.service';

describe('isCashfreePaymentMatch', () => {
  const attempt = {
    cashfree_order_id: 'rb_order_123',
    total_amount: 349.5,
  };

  const payment = {
    order_id: 'rb_order_123',
    payment_status: 'SUCCESS',
    payment_currency: 'INR',
    order_amount: 349.5,
    payment_amount: 349.5,
    cf_payment_id: 123456789,
  };

  it('accepts a successful payment with the exact order, amount and currency', () => {
    expect(isCashfreePaymentMatch(payment, attempt)).toBe(true);
  });

  it.each([
    [{ ...payment, order_id: 'another-order' }, 'wrong order'],
    [{ ...payment, payment_status: 'PENDING' }, 'pending payment'],
    [{ ...payment, payment_currency: 'USD' }, 'wrong currency'],
    [{ ...payment, order_amount: 349 }, 'provider order amount mismatch'],
    [{ ...payment, payment_amount: 300 }, 'captured payment amount mismatch'],
    [{ ...payment, cf_payment_id: null }, 'missing provider payment ID'],
  ])('rejects %s', (invalidPayment) => {
    expect(isCashfreePaymentMatch(invalidPayment, attempt)).toBe(false);
  });

  it('rejects an invalid expected amount', () => {
    expect(
      isCashfreePaymentMatch(payment, { ...attempt, total_amount: 'not-a-number' }),
    ).toBe(false);
  });
});


describe('isCashfreeWebhookSignatureValid', () => {
  const secret = 'cashfree-webhook-test-secret';
  const timestamp = '1764000000';
  const rawBody = Buffer.from('{"type":"PAYMENT_SUCCESS_WEBHOOK","data":{}}');

  function signatureFor(body: Buffer, time: string): string {
    return crypto.createHmac('sha256', secret)
      .update(time + body.toString('utf8'))
      .digest('base64');
  }

  it('accepts a valid signature over the exact timestamp and raw body', () => {
    expect(
      isCashfreeWebhookSignatureValid(
        signatureFor(rawBody, timestamp),
        timestamp,
        rawBody,
        secret,
      ),
    ).toBe(true);
  });

  it('rejects a modified body', () => {
    expect(
      isCashfreeWebhookSignatureValid(
        signatureFor(rawBody, timestamp),
        timestamp,
        Buffer.from('{"type":"PAYMENT_FAILED_WEBHOOK"}'),
        secret,
      ),
    ).toBe(false);
  });

  it('rejects a modified timestamp or signature', () => {
    expect(
      isCashfreeWebhookSignatureValid(
        signatureFor(rawBody, timestamp),
        '1764000001',
        rawBody,
        secret,
      ),
    ).toBe(false);
    expect(
      isCashfreeWebhookSignatureValid('invalid', timestamp, rawBody, secret),
    ).toBe(false);
  });
});


describe('cashfreeRefundPaymentStatus', () => {
  it.each([
    ['SUCCESS', 'refunded'],
    ['FAILED', 'paid'],
    ['CANCELLED', 'paid'],
    ['PENDING', 'refund_pending'],
    ['ONHOLD', 'refund_pending'],
    ['UNKNOWN', 'refund_pending'],
  ])('maps provider refund status %s safely', (providerStatus, expected) => {
    expect(cashfreeRefundPaymentStatus(providerStatus)).toBe(expected);
  });
});
