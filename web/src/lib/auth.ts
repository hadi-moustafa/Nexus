import { cookies } from "next/headers";
import { type NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export interface AuthUser {
  userId: string;
  email: string | undefined;
}

/**
 * Validates the caller's identity from a Route Handler request.
 *
 * - Web (SSR): reads the Supabase session cookie automatically.
 * - Mobile: reads the `Authorization: Bearer <access_token>` header
 *   and verifies the JWT against Supabase.
 *
 * Returns an AuthUser on success, or a 401 NextResponse on failure.
 * Route handlers should check `result instanceof NextResponse` to detect failure.
 *
 * @example
 * export async function GET(request: NextRequest) {
 *   const auth = await requireAuth(request);
 *   if (auth instanceof NextResponse) return auth; // 401
 *   // auth.userId is now safe to use
 * }
 */
export async function requireAuth(
  request: NextRequest
): Promise<AuthUser | NextResponse> {
  // --- Bearer token path (mobile clients) ---
  const authHeader = request.headers.get("authorization");
  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);
    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data.user) {
      return NextResponse.json(
        { error: { code: "UNAUTHORIZED", message: "Invalid or expired token" } },
        { status: 401 }
      );
    }
    return { userId: data.user.id, email: data.user.email };
  }

  // --- Cookie session path (web SSR clients) ---
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);
  const { data, error } = await supabase.auth.getUser();
  if (error || !data.user) {
    return NextResponse.json(
      { error: { code: "UNAUTHORIZED", message: "Not authenticated" } },
      { status: 401 }
    );
  }
  return { userId: data.user.id, email: data.user.email };
}
