/**
 * Jest bootstrap.
 *
 * src/supabase.ts calls createClient() at import time. There is no .env in CI,
 * so it threw "supabaseUrl is required" and killed 24 test suites at import -
 * before a single test ran.
 *
 * Stubbing the module means no test can reach a real Supabase project.
 * Anything that needs data must mock the client explicitly.
 */
jest.mock('@supabase/supabase-js', () => {
  const chain: any = new Proxy(function () {}, {
    get: (_t, prop) => (prop === 'then' ? undefined : chain),
    apply: () => chain,
  });

  return {
    createClient: () => ({
      auth: chain,
      from: () => chain,
      rpc: () => chain,
      storage: chain,
      channel: () => chain,
      removeChannel: () => Promise.resolve(),
      realtime: chain,
    }),
  };
});

jest.mock('firebase-admin', () => ({
  credential: { cert: () => ({}) },
  initializeApp: () => ({}),
  messaging: () => ({ send: () => Promise.resolve() }),
  storage: () => ({ bucket: () => ({}) }),
}));

process.env.SUPABASE_URL ??= 'http://supabase.test';
process.env.SUPABASE_SERVICE_ROLE_KEY ??= 'test-service-role-key';
