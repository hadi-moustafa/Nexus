import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

export interface AuthUser {
  userId: string;
  email: string | undefined;
}

/**
 * Validates the caller's identity from a Route Handler request.
 *
 * Uses the service-role client for JWT verification so it never touches
 * the auth-token cookie lock. Supports two paths:
 *
 * - Mobile: `Authorization: Bearer <access_token>` header
 * - Web:    Supabase session cookie (`sb-*-auth-token`)
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

  // Extract the JWT — prefer Authorization header (mobile), then cookie (web)
  let token: string | null = null;

  const authHeader = request.headers.get("authorization");
  if (authHeader?.startsWith("Bearer ")) {
    token = authHeader.slice(7);
  } else {
    // Parse the Supabase session cookie — it's a JSON-encoded object
    const projectRef = process.env.NEXT_PUBLIC_SUPABASE_URL
      ?.replace("https://", "")
      .replace(".supabase.co", "");

    const cookieName = `sb-${projectRef}-auth-token`;
    const raw = request.cookies.get(cookieName)?.value;

    if (raw) {
      try {
        // The cookie may be URL-encoded
        const decoded = decodeURIComponent(raw);
        const parsed = JSON.parse(decoded) as { access_token?: string };
        token = parsed.access_token ?? null;
      } catch {
        // Malformed cookie — fall through to unauthorized
      }
    }

    // Some Supabase versions chunk the cookie as base64 parts
    if (!token) {
      const chunkKeys = Array.from(request.cookies.getAll())
        .map((c) => c.name)
        .filter((n) => n.startsWith(`${cookieName}.`));

      if (chunkKeys.length > 0) {
        chunkKeys.sort();
        const combined = chunkKeys
          .map((k) => request.cookies.get(k)?.value ?? "")
          .join("");
        try {
          const decoded = decodeURIComponent(combined);
          const parsed = JSON.parse(decoded) as { access_token?: string };
          token = parsed.access_token ?? null;
        } catch {
          // ignore
        }
      }
    }
  }

  if (!token) return unauthorized();

  // Verify via service client — does NOT touch the cookie lock
  const supabase = createServiceClient();
  const { data, error } = await supabase.auth.getUser(token);

  if (error || !data.user) {
    return unauthorized("Invalid or expired token");
  }

  return { userId: data.user.id, email: data.user.email };
}
