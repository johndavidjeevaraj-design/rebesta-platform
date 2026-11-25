-- Serialize rider acceptance against other acceptance attempts.
-- The order row lock is the single authority for the transition from ready
-- to accepted_for_delivery. This also enforces active personal-offer ownership.
create or replace function public.accept_delivery_order(
  p_order_id uuid,
  p_partner_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order public.orders%rowtype;
  v_active_offer_partner uuid;
begin
  select *
    into v_order
    from public.orders
   where id = p_order_id
   for update;

  if not found then
    raise exception 'Order not found';
  end if;

  if v_order.order_status <> 'ready' or v_order.delivery_partner_id is not null then
    raise exception 'Order is no longer available';
  end if;

  -- A personal offer reserves this order for its recipient until it expires.
  select delivery_partner_id
    into v_active_offer_partner
    from public.delivery_offers
   where order_id = p_order_id
     and status = 'pending'
     and expires_at > now()
   limit 1;

  if found and v_active_offer_partner <> p_partner_id then
    raise exception 'This order is currently offered to another delivery partner';
  end if;

  -- Do not assign a rider who is already holding another live offer.
  if exists (
    select 1
      from public.delivery_offers
     where delivery_partner_id = p_partner_id
       and status = 'pending'
       and expires_at > now()
       and order_id <> p_order_id
  ) then
    raise exception 'You already have another active delivery offer';
  end if;

  update public.orders
     set delivery_partner_id = p_partner_id,
         assigned_at = now(),
         order_status = 'accepted_for_delivery'
   where id = p_order_id
     and order_status = 'ready'
     and delivery_partner_id is null
  returning * into v_order;

  if not found then
    raise exception 'Order acceptance conflict';
  end if;

  update public.delivery_offers
     set status = 'accepted',
         responded_at = now()
   where order_id = p_order_id
     and delivery_partner_id = p_partner_id
     and status = 'pending';

  update public.delivery_offers
     set status = 'superseded',
         responded_at = now()
   where order_id = p_order_id
     and status = 'pending';

  return jsonb_build_object('order', to_jsonb(v_order));
end;
$$;

revoke all on function public.accept_delivery_order(uuid, uuid) from public, anon, authenticated;
grant execute on function public.accept_delivery_order(uuid, uuid) to service_role;
