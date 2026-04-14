import { createBrowserClient } from "@supabase/ssr";
import type { SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!;

// Singleton — one instance per browser tab.
// Multiple calls to createBrowserClient() create separate auth-lock holders,
// causing "Lock was released because another request stole it" errors.
let _client: SupabaseClient | null = null;

export const createClient = (): SupabaseClient => {
  if (_client) return _client;
  _client = createBrowserClient(supabaseUrl, supabaseKey);
  return _client;
};
