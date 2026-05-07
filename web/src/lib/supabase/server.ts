import { createServerClient } from "@supabase/ssr";
import { createClient as createSupabaseClient } from "@supabase/supabase-js";
import { cookies } from "next/headers";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!;

/**
 * Auth-aware client — reads/writes cookies for session management.
 * Use this in route handlers and server actions where you need the user's identity.
 */
export const createClient = (cookieStore: Awaited<ReturnType<typeof cookies>>) => {
  return createServerClient(
    supabaseUrl,
    supabaseKey,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            );
          } catch {
            // Called from a Server Component — safe to ignore.
          }
        },
      },
    }
  );
};

/**
 * Cookie-free client for public reads (no auth, no lock contention).
 * Auth features are disabled to prevent session-detection network calls on init.
 */
export const createPublicClient = () =>
  createSupabaseClient(supabaseUrl, supabaseKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });

/**
 * Service-role client — bypasses RLS entirely.
 * Use ONLY in trusted server-side contexts (webhooks, cron jobs, admin routes).
 * NEVER expose to the client or use for user-initiated reads.
 */
export const createServiceClient = () =>
  createSupabaseClient(
    supabaseUrl,
    process.env.SUPABASE_SERVICE_ROLE_KEY!,
  );
