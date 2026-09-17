import { createClient } from '@supabase/supabase-js';
import * as dotenv from 'dotenv';

dotenv.config();

console.log('========== SUPABASE CONFIG ==========');
console.log(
  'SUPABASE_URL:',
  process.env.SUPABASE_URL
    ? process.env.SUPABASE_URL
    : 'MISSING',
);
console.log(
  'SUPABASE_SERVICE_ROLE_KEY:',
  process.env.SUPABASE_SERVICE_ROLE_KEY
    ? 'LOADED'
    : 'MISSING',
);
console.log('=====================================');

export const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!,
);