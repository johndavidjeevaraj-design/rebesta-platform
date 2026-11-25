-- Auditable manual payout settlement for rider earnings.
CREATE TABLE IF NOT EXISTS public.delivery_payouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_partner_id uuid NOT NULL REFERENCES public.delivery_partners(id),
  payout_reference text NOT NULL UNIQUE,
  amount numeric(12,2) NOT NULL CHECK (amount > 0),
  status text NOT NULL DEFAULT 'paid' CHECK (status IN ('paid')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_delivery_payouts_partner_created
  ON public.delivery_payouts(delivery_partner_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.settle_delivery_payout(
  p_partner_id uuid,
  p_payout_reference text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_partner public.delivery_partners%ROWTYPE;
  v_existing public.delivery_payouts%ROWTYPE;
  v_payout public.delivery_payouts%ROWTYPE;
  v_amount numeric(12,2);
BEGIN
  IF p_payout_reference IS NULL OR length(trim(p_payout_reference)) < 4 THEN
    RAISE EXCEPTION 'A valid payout reference is required';
  END IF;

  SELECT * INTO v_existing
  FROM public.delivery_payouts
  WHERE payout_reference = trim(p_payout_reference);

  IF FOUND THEN
    IF v_existing.delivery_partner_id <> p_partner_id THEN
      RAISE EXCEPTION 'Payout reference already belongs to another rider';
    END IF;
    RETURN jsonb_build_object('payout', to_jsonb(v_existing), 'already_processed', true);
  END IF;

  SELECT * INTO v_partner
  FROM public.delivery_partners
  WHERE id = p_partner_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Delivery partner not found';
  END IF;

  SELECT COALESCE(SUM(amount), 0)::numeric(12,2)
  INTO v_amount
  FROM public.delivery_earnings
  WHERE delivery_partner_id = p_partner_id
    AND status = 'pending';

  IF v_amount <= 0 THEN
    RAISE EXCEPTION 'No pending earnings available for payout';
  END IF;

  INSERT INTO public.delivery_payouts (
    delivery_partner_id, payout_reference, amount, status
  ) VALUES (
    p_partner_id, trim(p_payout_reference), v_amount, 'paid'
  ) RETURNING * INTO v_payout;

  UPDATE public.delivery_earnings
  SET status = 'paid'
  WHERE delivery_partner_id = p_partner_id
    AND status = 'pending';

  UPDATE public.delivery_partners
  SET wallet_balance = GREATEST(COALESCE(wallet_balance, 0) - v_amount, 0),
      pending_payout = GREATEST(COALESCE(pending_payout, 0) - v_amount, 0)
  WHERE id = p_partner_id;

  RETURN jsonb_build_object('payout', to_jsonb(v_payout), 'already_processed', false);
END;
$$;

REVOKE ALL ON FUNCTION public.settle_delivery_payout(uuid, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.settle_delivery_payout(uuid, text)
  TO service_role;
