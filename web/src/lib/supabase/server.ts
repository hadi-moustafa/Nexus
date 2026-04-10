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
 * Uses a 5-second fetch timeout so SSR fails fast instead of hanging 10s.
 */
export const createPublicClient = () =>
  createSupabaseClient(supabaseUrl, supabaseKey, {
    global: {
      fetch: (url, options) => {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 5000);
        return fetch(url, { ...options, signal: controller.signal }).finally(() =>
          clearTimeout(timer)
        );
      },
    },
  });
