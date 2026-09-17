process.env.SUPABASE_URL = 'http://supabase.test';
process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-service-role-key';

jest.mock('@supabase/supabase-js', () => {
  const chain = new Proxy(function () {}, {
    get: (_target, prop) => prop === 'then' ? undefined : chain,
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
  credential: {
    cert: () => ({}),
  },
  initializeApp: () => ({}),
  messaging: () => ({
    send: () => Promise.resolve(),
  }),
  storage: () => ({
    bucket: () => ({}),
  }),
}));
