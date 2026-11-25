-- Ensure an order can have at most one active personal rider offer.
--
-- Concurrent dispatch workers can both read "no pending offer" before
-- either inserts. This database constraint makes the claim race-safe.
-- Expired pending rows are closed first so they do not block a new offer.

update public.delivery_offers
set status = 'expired',
    responded_at = coalesce(responded_at, now())
where status = 'pending'
  and expires_at <= now();

with ranked_pending as (
  select
    id,
    row_number() over (
      partition by order_id
      order by offered_at desc, created_at desc, id desc
    ) as position
  from public.delivery_offers
  where status = 'pending'
)
update public.delivery_offers as offer
set status = 'superseded',
    responded_at = coalesce(offer.responded_at, now())
from ranked_pending as ranked
where offer.id = ranked.id
  and ranked.position > 1;

create unique index if not exists idx_delivery_offers_one_pending_per_order
  on public.delivery_offers(order_id)
  where status = 'pending';
