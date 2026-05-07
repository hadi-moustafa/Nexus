import { type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { requireAuth } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";
import { revokeAllSessions } from "@/lib/db/sessions";

/**
 * POST /api/v1/auth/signout
 *
 * Signs the user out and clears the session cookie.
 * Mobile clients should also clear their flutter_secure_storage after calling this.
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth; // 401

  try {
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);
    await supabase.auth.signOut();

    void logAction("sign_out", auth.userId, {}, request);
    void revokeAllSessions(auth.userId);

    return Response.json({ data: { success: true } });
  } catch (err) {
    console.error("[POST /api/v1/auth/signout]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Sign out failed" } },
      { status: 500 }
    );
  }
}
