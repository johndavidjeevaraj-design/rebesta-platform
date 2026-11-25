-- Record only stock that was actually deducted at restaurant acceptance.
-- This allows a later cancellation to restore exact quantities exactly once.
CREATE TABLE IF NOT EXISTS public.order_stock_consumptions (
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  menu_id uuid NOT NULL REFERENCES public.menu_items(id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  restored_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (order_id, menu_id)
);

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

  IF NOT FOUND THEN RAISE EXCEPTION 'Order not found'; END IF;
  IF v_order.order_status <> 'pending' THEN
    RAISE EXCEPTION 'Order is no longer pending';
  END IF;
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

    IF NOT FOUND THEN RAISE EXCEPTION 'An order item is no longer available'; END IF;
    IF NOT COALESCE(v_menu.is_available, false) THEN
      RAISE EXCEPTION 'An order item is currently unavailable';
    END IF;

    IF v_menu.stock_quantity IS NOT NULL THEN
      IF v_menu.stock_quantity < v_item.quantity THEN
        RAISE EXCEPTION 'Insufficient stock for menu item %', v_menu.name;
      END IF;
      UPDATE public.menu_items
      SET stock_quantity = stock_quantity - v_item.quantity
      WHERE id = v_menu.id;

      INSERT INTO public.order_stock_consumptions(order_id, menu_id, quantity)
      VALUES (p_order_id, v_menu.id, v_item.quantity);
    END IF;
  END LOOP;

  UPDATE public.orders
  SET order_status = 'accepted'
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  RETURN jsonb_build_object('order', to_jsonb(v_order));
END;
$$;

CREATE OR REPLACE FUNCTION public.cancel_restaurant_order_and_restore_stock(
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
  v_consumption record;
BEGIN
  SELECT * INTO v_order
  FROM public.orders
  WHERE id = p_order_id
    AND restaurant_partner_id = p_partner_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Order not found'; END IF;
  IF v_order.order_status NOT IN ('accepted', 'preparing') THEN
    RAISE EXCEPTION 'Only accepted or preparing orders can be cancelled by the restaurant';
  END IF;
  IF v_order.payment_status NOT IN ('pending', 'failed', 'refunded') THEN
    RAISE EXCEPTION 'Paid orders must be refunded before restaurant cancellation';
  END IF;

  FOR v_consumption IN
    SELECT menu_id, quantity
    FROM public.order_stock_consumptions
    WHERE order_id = p_order_id
      AND restored_at IS NULL
    ORDER BY menu_id
    FOR UPDATE
  LOOP
    UPDATE public.menu_items
    SET stock_quantity = stock_quantity + v_consumption.quantity
    WHERE id = v_consumption.menu_id;

    UPDATE public.order_stock_consumptions
    SET restored_at = now()
    WHERE order_id = p_order_id
      AND menu_id = v_consumption.menu_id
      AND restored_at IS NULL;
  END LOOP;

  UPDATE public.orders
  SET order_status = 'cancelled'
  WHERE id = p_order_id
    AND restaurant_partner_id = p_partner_id
  RETURNING * INTO v_order;

  RETURN jsonb_build_object('order', to_jsonb(v_order));
END;
$$;

REVOKE ALL ON FUNCTION public.accept_restaurant_order(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.cancel_restaurant_order_and_restore_stock(uuid, uuid)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.accept_restaurant_order(uuid, uuid)
  TO service_role;
GRANT EXECUTE ON FUNCTION public.cancel_restaurant_order_and_restore_stock(uuid, uuid)
  TO service_role;
