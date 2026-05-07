import { type NextRequest, NextResponse } from "next/server";
import { requireAdminApi } from "@/lib/admin";
import { createServiceClient } from "@/lib/supabase/server";
import { revokeAllSessions, getAdminUserSessions } from "@/lib/db/sessions";
import { logAction } from "@/lib/audit";

interface RouteContext {
  params: Promise<{ userId: string }>;
}

/**
 * GET /api/v1/admin/users/[userId]/sessions
 * List all sessions (active + revoked) for a user. Admin only.
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { userId } = await params;
    const sessions = await getAdminUserSessions(userId);
    return NextResponse.json({ data: sessions });
  } catch (err) {
    console.error("[GET /api/v1/admin/users/[userId]/sessions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch sessions" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/admin/users/[userId]/sessions
 * Force sign-out a user from all devices. Admin only.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { userId } = await params;
    const supabase = createServiceClient();

    await supabase.auth.admin.signOut(userId, "global");
    await revokeAllSessions(userId);

    void logAction("admin_force_signout", auth.userId, { targetUserId: userId }, request);

    return NextResponse.json({ data: { success: true } });
  } catch (err) {
    console.error("[DELETE /api/v1/admin/users/[userId]/sessions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to force sign-out" } },
      { status: 500 }
    );
  }
}
