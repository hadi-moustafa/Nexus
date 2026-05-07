import { type NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth";
import { revokeSession } from "@/lib/db/sessions";
import { logAction } from "@/lib/audit";

interface RouteContext {
  params: Promise<{ sessionId: string }>;
}

/**
 * DELETE /api/v1/user/sessions/[sessionId]
 * Revoke a specific session record.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth;

  try {
    const { sessionId } = await params;
    const ok = await revokeSession(sessionId, auth.userId);

    if (!ok) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "Session not found" } },
        { status: 404 }
      );
    }

    void logAction("session_revoked", auth.userId, { sessionId }, request);

    return NextResponse.json({ data: { success: true } });
  } catch (err) {
    console.error("[DELETE /api/v1/user/sessions/[sessionId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to revoke session" } },
      { status: 500 }
    );
  }
}
