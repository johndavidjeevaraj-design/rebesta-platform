-- Cashfree PG migration for the food-delivery platform.
-- Keep Razorpay identifiers for historical attempts while all new checkout
-- attempts are explicitly marked as Cashfree.
ALTER TABLE public.payment_attempts
  ADD COLUMN IF NOT EXISTS payment_provider text NOT NULL DEFAULT 'razorpay',
  ADD COLUMN IF NOT EXISTS cashfree_order_id text,
  ADD COLUMN IF NOT EXISTS cashfree_payment_session_id text,
  ADD COLUMN IF NOT EXISTS cashfree_payment_id text,
  ADD COLUMN IF NOT EXISTS cashfree_idempotency_key uuid NOT NULL DEFAULT gen_random_uuid();

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS cashfree_order_id text,
  ADD COLUMN IF NOT EXISTS cashfree_payment_id text,
  ADD COLUMN IF NOT EXISTS cashfree_refund_id text,
  ADD COLUMN IF NOT EXISTS cashfree_refund_status text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.payment_attempts'::regclass
      AND conname = 'payment_attempts_payment_provider_check'
  ) THEN
    ALTER TABLE public.payment_attempts
      ADD CONSTRAINT payment_attempts_payment_provider_check
      CHECK (payment_provider IN ('razorpay', 'cashfree'));
  END IF;
END;
$$;

CREATE UNIQUE INDEX IF NOT EXISTS payment_attempts_cashfree_order_id_unique
  ON public.payment_attempts(cashfree_order_id)
  WHERE cashfree_order_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS payment_attempts_cashfree_idempotency_key_unique
  ON public.payment_attempts(cashfree_idempotency_key);

CREATE UNIQUE INDEX IF NOT EXISTS payment_attempts_cashfree_payment_id_unique
  ON public.payment_attempts(cashfree_payment_id)
  WHERE cashfree_payment_id IS NOT NULL;


CREATE UNIQUE INDEX IF NOT EXISTS orders_cashfree_order_id_unique
  ON public.orders(cashfree_order_id)
  WHERE cashfree_order_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS orders_cashfree_payment_id_unique
  ON public.orders(cashfree_payment_id)
  WHERE cashfree_payment_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS orders_cashfree_refund_id_unique
  ON public.orders(cashfree_refund_id)
  WHERE cashfree_refund_id IS NOT NULL;

-- Cashfree-specific conversion keeps legacy Razorpay conversion intact for
-- historical attempts. The provider is verified by the backend before RPC.
CREATE OR REPLACE FUNCTION public.create_paid_order_from_cashfree_attempt(
  p_attempt_id uuid,
  p_payment_id text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt public.payment_attempts%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_existing public.orders%ROWTYPE;
  v_snapshot jsonb;
  v_delivery_otp text;
BEGIN
  SELECT * INTO v_attempt
  FROM public.payment_attempts
  WHERE id = p_attempt_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment attempt not found';
  END IF;

  IF v_attempt.payment_provider <> 'cashfree'
     OR v_attempt.cashfree_order_id IS NULL THEN
    RAISE EXCEPTION 'Payment attempt is not a Cashfree attempt';
  END IF;

  IF v_attempt.order_id IS NOT NULL THEN
    SELECT * INTO v_order FROM public.orders WHERE id = v_attempt.order_id;
    IF FOUND THEN
      RETURN jsonb_build_object('created', false, 'order', to_jsonb(v_order));
    END IF;
    RAISE EXCEPTION 'Attempt references missing order';
  END IF;

  SELECT * INTO v_existing
  FROM public.orders
  WHERE cashfree_order_id = v_attempt.cashfree_order_id;

  IF FOUND THEN
    UPDATE public.payment_attempts SET
      status = 'success',
      cashfree_payment_id = v_existing.cashfree_payment_id,
      order_id = v_existing.id
    WHERE id = v_attempt.id;

    RETURN jsonb_build_object('created', false, 'order', to_jsonb(v_existing));
  END IF;

  IF p_payment_id IS NULL OR length(trim(p_payment_id)) = 0 THEN
    RAISE EXCEPTION 'Cashfree payment ID is required';
  END IF;

  IF v_attempt.order_type NOT IN ('delivery', 'pickup') THEN
    RAISE EXCEPTION 'Payment attempt order type is invalid';
  END IF;

  IF v_attempt.order_type = 'delivery' AND v_attempt.address_id IS NULL THEN
    RAISE EXCEPTION 'Delivery address is required';
  END IF;

  IF v_attempt.order_type = 'pickup' AND v_attempt.address_id IS NOT NULL THEN
    RAISE EXCEPTION 'Pickup orders cannot have a delivery address';
  END IF;

  v_delivery_otp := floor(1000 + random() * 9000)::text;

  INSERT INTO public.orders (
    customer_id, restaurant_partner_id, address_id, order_type,
    discount_amount, delivery_fee, total_amount,
    payment_status, order_status, cashfree_order_id,
    cashfree_payment_id, payment_completed_at,
    delivery_otp, otp_verified
  ) VALUES (
    v_attempt.customer_id, v_attempt.restaurant_partner_id,
    v_attempt.address_id, v_attempt.order_type,
    v_attempt.discount_amount, v_attempt.delivery_fee, v_attempt.total_amount,
    'paid', 'pending', v_attempt.cashfree_order_id,
    p_payment_id, now(), v_delivery_otp, false
  ) RETURNING * INTO v_order;

  v_snapshot := v_attempt.cart_items_snapshot;
  IF jsonb_typeof(v_snapshot) <> 'array' OR jsonb_array_length(v_snapshot) = 0 THEN
    RAISE EXCEPTION 'Payment attempt cart snapshot is invalid';
  END IF;

  INSERT INTO public.order_items (order_id, menu_id, quantity, price)
  SELECT v_order.id,
         (item->>'menuItemId')::uuid,
         (item->>'quantity')::integer,
         (item->>'price')::numeric
  FROM jsonb_array_elements(v_snapshot) item;

  UPDATE public.payment_attempts SET
    status = 'success',
    cashfree_payment_id = p_payment_id,
    order_id = v_order.id
  WHERE id = v_attempt.id;

  DELETE FROM public.cart_items
  WHERE id IN (
    SELECT (item->>'cartItemId')::uuid
    FROM jsonb_array_elements(v_snapshot) item
    WHERE item ? 'cartItemId'
  );

  RETURN jsonb_build_object('created', true, 'order', to_jsonb(v_order));
END;
$$;

REVOKE ALL ON FUNCTION public.create_paid_order_from_cashfree_attempt(uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_paid_order_from_cashfree_attempt(uuid, text)
  TO service_role;
