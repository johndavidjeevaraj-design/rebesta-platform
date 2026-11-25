-- Ensure the rider wallet and earnings schema exists before the RPC
-- is created. These fields are already consumed by the delivery app.
alter table public.delivery_partners
  add column if not exists wallet_balance numeric(12,2) not null default 0,
  add column if not exists total_earnings numeric(12,2) not null default 0,
  add column if not exists pending_payout numeric(12,2) not null default 0,
  add column if not exists completed_deliveries integer not null default 0;

create table if not exists public.delivery_earnings (
  id uuid primary key default gen_random_uuid(),
  delivery_partner_id uuid not null
    references public.delivery_partners(id) on delete cascade,
  order_id uuid not null
    references public.orders(id) on delete cascade,
  amount numeric(12,2) not null check (amount > 0),
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'reversed')),
  created_at timestamptz not null default now(),
  constraint delivery_earnings_order_id_key unique (order_id)
);

create index if not exists idx_delivery_earnings_partner_created
  on public.delivery_earnings(delivery_partner_id, created_at desc);

-- Atomically verify delivery OTP, transition order and credit delivery earnings.
create or replace function public.complete_delivery_with_otp(p_order_id uuid, p_partner_id uuid, p_otp text, p_amount numeric default 40)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_order orders%rowtype;
  v_earning delivery_earnings%rowtype;
  v_new_earning boolean := false;
  v_amount numeric := p_amount;
begin
  if v_amount <= 0 then raise exception 'Invalid earning amount'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_order_id::text, 0));
  select * into v_order from orders where id = p_order_id and delivery_partner_id = p_partner_id for update;
  if not found then raise exception 'Order not found or not assigned to rider'; end if;
  if v_order.order_status = 'delivered' and v_order.otp_verified then
    select * into v_earning from delivery_earnings where order_id = p_order_id;
    return jsonb_build_object('order',to_jsonb(v_order),'earning',to_jsonb(v_earning),'already_completed',true);
  end if;
  if v_order.order_status <> 'arrived_at_customer' or v_order.otp_verified then raise exception 'Order is not eligible for OTP completion'; end if;
  if coalesce(v_order.delivery_otp::text,'') <> p_otp then raise exception 'Invalid OTP'; end if;
  update orders set otp_verified=true, order_status='delivered', delivered_at=now()
    where id=p_order_id and delivery_partner_id=p_partner_id and order_status='arrived_at_customer' and otp_verified=false
    returning * into v_order;
  if not found then raise exception 'Delivery completion conflict'; end if;
  select * into v_earning from delivery_earnings where order_id=p_order_id;
  if not found then
    insert into delivery_earnings(delivery_partner_id,order_id,amount,status)
      values(p_partner_id,p_order_id,v_amount,'pending') returning * into v_earning;
    v_new_earning := true;
    update delivery_partners set wallet_balance=coalesce(wallet_balance,0)+v_amount,
      total_earnings=coalesce(total_earnings,0)+v_amount,
      pending_payout=coalesce(pending_payout,0)+v_amount,
      completed_deliveries=coalesce(completed_deliveries,0)+1 where id=p_partner_id;
    if not found then raise exception 'Delivery partner wallet missing'; end if;
  end if;
  return jsonb_build_object('order',to_jsonb(v_order),'earning',to_jsonb(v_earning),'already_completed',not v_new_earning);
end;
$$;
revoke all on function public.complete_delivery_with_otp(uuid,uuid,text,numeric) from public;
grant execute on function public.complete_delivery_with_otp(uuid,uuid,text,numeric) to service_role;
