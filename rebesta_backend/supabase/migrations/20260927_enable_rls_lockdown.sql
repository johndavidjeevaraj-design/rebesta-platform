-- ============================================================
-- MIGRATION: Enable RLS lockdown (deny-by-default)
-- Date: 2026-09-27
-- ============================================================
--
-- WHY
-- ----
-- The Supabase project exposes PostgREST publicly. Anyone
-- holding the ANON KEY (which ships inside every app build)
-- can query https://<project>.supabase.co/rest/v1/<table>
-- directly. On any table WITHOUT Row Level Security, that
-- means full read AND write access to customer data, orders,
-- wallets and payments.
--
-- All three apps talk ONLY to the Nest backend, which uses
-- the SERVICE ROLE key - and the service role BYPASSES RLS.
-- So this migration locks every anon/authenticated request
-- out of every table without touching app functionality.
--
-- WHAT IT DOES
-- ------------
-- Enables RLS on every table with NO policies. In Postgres,
-- RLS enabled + zero policies = default DENY for the
-- anon and authenticated roles. No app traffic uses those
-- roles, so nothing breaks.
--
-- Run in the Supabase SQL Editor.
-- ============================================================

ALTER TABLE public.addresses                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.banners                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cart_items               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.carts                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_usages            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_wallets         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_earnings        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_kyc_documents   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_offers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_partners        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_attempts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurant_partners      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions      ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- VERIFY (run after the statements above)
-- ============================================================
-- 1) Every table must show rowsecurity = t:
--
--    SELECT tablename, rowsecurity
--    FROM pg_tables
--    WHERE schemaname = 'public'
--    ORDER BY tablename;
--
-- 2) List any pre-existing policies - the list should be
--    empty, or contain only policies you created on purpose.
--    RLS does not remove existing policies; a permissive
--    policy would keep a table open. If anything unexpected
--    shows up, drop it with:
--    DROP POLICY <name> ON public.<table>;
--
--    SELECT schemaname, tablename, policyname, permissive, roles, cmd
--    FROM pg_policies
--    WHERE schemaname = 'public'
--    ORDER BY tablename;
--
-- 3) Sanity check that anon reads are now denied (should
--    return an error or zero rows, never data):
--
--    -- with the anon key as the API key:
--    curl "https://<project>.supabase.co/rest/v1/orders?select=*" \
--      -H "apikey: <ANON_KEY>"
--
-- NOTE - storage buckets (menu/restaurant images) are managed
-- in Dashboard > Storage > Policies, not here. The menu image
-- bucket should allow public READ only; writes only via the
-- backend service role.
-- ============================================================
