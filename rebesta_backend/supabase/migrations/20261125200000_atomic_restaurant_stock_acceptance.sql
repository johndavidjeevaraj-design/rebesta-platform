-- Optional stock tracking: NULL means unlimited/untracked for existing dishes.
ALTER TABLE public.menu_items
  ADD COLUMN IF NOT EXISTS stock_quantity integer;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.menu_items'::regclass
      AND conname = 'menu_items_stock_quantity_nonnegative'
  ) THEN
    ALTER TABLE public.menu_items
      ADD CONSTRAINT menu_items_stock_quantity_nonnegative
      CHECK (stock_quantity IS NULL OR stock_quantity >= 0);
  END IF;
END;
$$;

-- Atomically accept a restaurant order and consume tracked stock.
-- The order row is locked first; menu rows are locked in stable ID order
-- so simultaneous acceptances cannot oversell or deadlock on item order.
CREATE OR REPLACE FUNCTION public.accept_restaurant_order(
  p_order_id uuid,
  p_partner_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_item record;
  v_menu public.menu_items%ROWTYPE;
BEGIN
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
    AND restaurant_partner_id = p_partner_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  IF v_order.order_status <> 'pending' THEN
    RAISE EXCEPTION 'Order is no longer pending';
  END IF;

  -- Razorpay-backed orders must be paid. COD orders have no Razorpay order ID.
  IF v_order.razorpay_order_id IS NOT NULL
     AND v_order.payment_status IS DISTINCT FROM 'paid' THEN
    RAISE EXCEPTION 'Online payment must be confirmed before accepting this order';
  END IF;

  FOR v_item IN
    SELECT menu_id, SUM(quantity)::integer AS quantity
    FROM public.order_items
    WHERE order_id = p_order_id
    GROUP BY menu_id
    ORDER BY menu_id
  LOOP
    SELECT * INTO v_menu
    FROM public.menu_items
    WHERE id = v_item.menu_id
      AND restaurant_partner_id = p_partner_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'An order item is no longer available';
    END IF;

    IF NOT v_menu.is_available THEN
      RAISE EXCEPTION 'An order item is currently unavailable';
    END IF;

    IF v_menu.stock_quantity IS NOT NULL THEN
      IF v_menu.stock_quantity < v_item.quantity THEN
        RAISE EXCEPTION 'Insufficient stock for menu item %', v_menu.name;
      END IF;

      UPDATE public.menu_items
      SET stock_quantity = stock_quantity - v_item.quantity
      WHERE id = v_menu.id;
    END IF;
  END LOOP;

  UPDATE public.orders
  SET order_status = 'accepted'
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  RETURN jsonb_build_object('order', to_jsonb(v_order));
END;
$$;

REVOKE ALL ON FUNCTION public.accept_restaurant_order(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.accept_restaurant_order(uuid, uuid)
  TO service_role;
