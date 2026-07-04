import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";
import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

export interface AuthUser {
  userId: string;
  email: string | undefined;
  /** Raw Supabase user_metadata (display name, avatar from OAuth providers) */
  userMetadata: Record<string, unknown>;
  /** Raw Supabase app_metadata (provider, roles set by the auth server) */
  appMetadata: Record<string, unknown>;
}

/**
 * Validates the caller's identity from a Route Handler request.
 *
 * - Mobile: `Authorization: Bearer <access_token>` header
 *   Verified directly against Supabase via the service-role client.
 *
 * - Web: Supabase session cookie, read via createServerClient so the
 *   cookie format is always handled correctly regardless of @supabase/ssr version.
 *
 * Returns an AuthUser on success, or a 401 NextResponse on failure.
 */
export async function requireAuth(
  request: NextRequest
): Promise<AuthUser | NextResponse> {
  const unauthorized = (msg = "Not authenticated") =>
    NextResponse.json(
      { error: { code: "UNAUTHORIZED", message: msg } },
      { status: 401 }
    );

  // ── Mobile: Authorization header ─────────────────────────────────────────
  const authHeader = request.headers.get("authorization");
  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    const supabase = createServiceClient();
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) return unauthorized("Invalid or expired token");
    const u = data.user;
    return {
      userId: u.id,
      email: u.email,
      userMetadata: (u.user_metadata ?? {}) as Record<string, unknown>,
      appMetadata: (u.app_metadata ?? {}) as Record<string, unknown>,
    };
  }

  // ── Web: cookie-based session via @supabase/ssr ───────────────────────────
  // Use createServerClient instead of hand-rolling cookie parsing so that
  // the correct cookie name, chunking, and encoding are handled automatically.
  try {
    const cookieStore = await cookies();
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!,
      {
        cookies: {
          getAll: () => cookieStore.getAll(),
          setAll: (cookiesToSet) => {
            try {
              cookiesToSet.forEach(({ name, value, options }) =>
                cookieStore.set(name, value, options)
              );
            } catch {
              // Called from a Route Handler — safe to ignore set errors.
            }
          },
        },
      }
    );

    const { data: { user }, error } = await supabase.auth.getUser();
    if (error || !user) return unauthorized();
    return {
      userId: user.id,
      email: user.email,
      userMetadata: (user.user_metadata ?? {}) as Record<string, unknown>,
      appMetadata: (user.app_metadata ?? {}) as Record<string, unknown>,
    };
  } catch {
    return unauthorized();
  }
}
