-- ============================================================
-- MIGRATION: Store hours for restaurants
-- Date: 2026-09-27
-- ============================================================
--
-- Adds opening / closing times and weekly closed days to
-- restaurants. Times are stored in the restaurant's LOCAL
-- time (IST at launch) as plain clock times - no timezone
-- conversion. `is_open` remains the live manual toggle the
-- partner controls from the dashboard; hours describe the
-- regular schedule (shown in the partner + customer apps).
--
-- closed_days: weekday numbers, 0 = Sunday ... 6 = Saturday
-- (matches Dart DateTime.weekday mapping: DateTime.sunday=0
-- is expressed as weekday % 7). Empty array = open all week.
--
-- NULL opening/closing time = no schedule set (manual toggle
-- is the only control).
--
-- Run in the Supabase SQL Editor.
-- ============================================================

ALTER TABLE public.restaurants
  ADD COLUMN IF NOT EXISTS opening_time TIME,
  ADD COLUMN IF NOT EXISTS closing_time TIME,
  ADD COLUMN IF NOT EXISTS closed_days INTEGER[] NOT NULL DEFAULT '{}';

-- ============================================================
-- VERIFY
-- ============================================================
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public'
--   AND table_name = 'restaurants'
--   AND column_name IN ('opening_time', 'closing_time', 'closed_days');
--
-- Expect: opening_time TIME (nullable), closing_time TIME
-- (nullable), closed_days ARRAY / INTEGER[] default '{}'.
-- ============================================================
