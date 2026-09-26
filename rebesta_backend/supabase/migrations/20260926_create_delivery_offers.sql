-- ============================================================
-- Swiggy-style dispatch: personal order offers to riders
-- ============================================================
--
-- Run this in the Supabase SQL editor (Dashboard -> SQL Editor).
--
-- The backend FAILS OPEN until this table exists: if the table
-- is missing, dispatch logs an error and falls back to the old
-- broadcast behaviour, so the platform keeps working either way.
--
-- Flow:
--   1. Order becomes ready -> best available rider gets a
--      PERSONAL offer (pending, expires in ~45 seconds,
--      configurable via DISPATCH_OFFER_TTL_SECONDS).
--   2. Rider accepts -> offer marked accepted, order assigned.
--   3. Rider declines -> offer marked declined, next rider
--      is offered immediately.
--   4. Offer expires -> marked expired, next rider is offered
--      (a background sweep also catches these).
--   5. Somebody else accepts -> other pending offers are
--      marked superseded.
-- ============================================================

create table if not exists public.delivery_offers (
  id uuid primary key default gen_random_uuid(),

  order_id uuid not null
    references public.orders(id) on delete cascade,

  delivery_partner_id uuid not null
    references public.delivery_partners(id) on delete cascade,

  status text not null default 'pending'
    check (
      status in (
        'pending',
        'accepted',
        'declined',
        'expired',
        'superseded'
      )
    ),

  offered_at timestamptz not null default now(),

  expires_at timestamptz not null,

  responded_at timestamptz,

  created_at timestamptz not null default now()
);

-- Look up all offers for one order
create index if not exists idx_delivery_offers_order
  on public.delivery_offers(order_id);

-- The expiry sweep: find pending offers past their expiry
create index if not exists idx_delivery_offers_pending
  on public.delivery_offers(status, expires_at)
  where status = 'pending';

-- Fairness ranking: offers each rider received today
create index if not exists idx_delivery_offers_partner_day
  on public.delivery_offers(delivery_partner_id, offered_at);
