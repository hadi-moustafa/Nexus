import { type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";
import { revokeAllSessions } from "@/lib/db/sessions";
import { requireAuth } from "@/lib/auth";

/**
 * POST /api/v1/auth/signout
 *
 * Clears the server-side session cookie and revokes all DB sessions.
 * Always succeeds — even if the session is already gone — so the client
 * can safely redirect to /login regardless of the server response.
 */
export async function POST(request: NextRequest) {
  // Best-effort: get the userId for audit log + session revocation.
  // If the token is already invalid (e.g. expired), we still clear cookies.
  let userId: string | null = null;
  try {
    const auth = await requireAuth(request);
    if (!(auth instanceof Response)) {
      userId = auth.userId;
    }
  } catch {
    // Session already gone — proceed to cookie cleanup
  }

  try {
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);
    // Calling signOut on the server client clears the SSR session cookie
    await supabase.auth.signOut();

    if (userId) {
      void logAction("sign_out", userId, {}, request);
      void revokeAllSessions(userId);
    }

    return Response.json({ data: { success: true } });
  } catch (err) {
    console.error("[POST /api/v1/auth/signout]", err);
    // Still return success — the client will redirect to /login either way
    return Response.json({ data: { success: true } });
  }
}
