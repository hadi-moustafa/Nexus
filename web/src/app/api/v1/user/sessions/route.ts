import { type NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth";
import { getUserSessions, revokeAllSessions } from "@/lib/db/sessions";
import { createServiceClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";

function getCurrentSessionId(request: NextRequest): string | undefined {
  const cookieHeader = request.headers.get("cookie") ?? "";
  const match = cookieHeader.match(/sb-[^-]+-auth-token=([^;]+)/);
  return match?.[1] ? undefined : undefined; // session ID not directly available from cookie
}

/**
 * GET /api/v1/user/sessions
 * List all active sessions for the authenticated user.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth;

  try {
    const sessions = await getUserSessions(auth.userId);
    return NextResponse.json({ data: sessions });
  } catch (err) {
    console.error("[GET /api/v1/user/sessions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch sessions" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/user/sessions
 * Revoke ALL sessions (sign out everywhere).
 */
export async function DELETE(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth;

  try {
    // Revoke all tokens in Supabase auth
    const supabase = createServiceClient();
    await supabase.auth.admin.signOut(auth.userId, "global");

    // Mark all session records as revoked
    await revokeAllSessions(auth.userId);

    void logAction("all_sessions_revoked", auth.userId, {}, request);

    return NextResponse.json({ data: { success: true } });
  } catch (err) {
    console.error("[DELETE /api/v1/user/sessions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to revoke sessions" } },
      { status: 500 }
    );
  }
}
