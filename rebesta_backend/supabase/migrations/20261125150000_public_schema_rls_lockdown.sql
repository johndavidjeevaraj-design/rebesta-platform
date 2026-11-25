-- Harden the public schema beyond the original table-by-table RLS list.
-- The mobile apps must access application data through the NestJS API,
-- which uses the Supabase service_role key. Do not apply if an app still
-- depends on direct anon/authenticated table access; migrate that traffic first.

DO $$
DECLARE
  table_record record;
BEGIN
  FOR table_record IN
    SELECT schemaname, tablename
    FROM pg_tables
    WHERE schemaname = 'public'
  LOOP
    EXECUTE format(
      'ALTER TABLE %I.%I ENABLE ROW LEVEL SECURITY',
      table_record.schemaname,
      table_record.tablename
    );
  END LOOP;
END
$$;

-- RLS policies do not override SQL privileges. Remove direct table and
-- sequence privileges from client roles; service_role retains its own grants
-- and bypasses RLS in Supabase.
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;

-- Verification:
-- SELECT tablename, rowsecurity
-- FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
--
-- SELECT grantee, table_name, privilege_type
-- FROM information_schema.role_table_grants
-- WHERE table_schema = 'public'
--   AND grantee IN ('anon', 'authenticated')
-- ORDER BY grantee, table_name, privilege_type;
--
-- Expected: rowsecurity=true for every public table and no direct
-- table privileges for anon/authenticated. Backend service_role access
-- must be smoke-tested immediately after applying this migration.
