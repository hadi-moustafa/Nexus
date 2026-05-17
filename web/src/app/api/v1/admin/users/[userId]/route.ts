import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";
import { logAction } from "@/lib/audit";

interface RouteContext {
  params: Promise<{ userId: string }>;
}

/**
 * PATCH /api/v1/admin/users/[userId]
 * Update a user's role. Admin only.
 *
 * Body: { role: "user" | "admin" }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { userId } = await params;
    const { role } = await request.json();

    if (!["user", "admin", "journalist", "banned"].includes(role)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "role must be 'user', 'admin', 'journalist', or 'banned'" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("users")
      .update({ role })
      .eq("id", userId)
      .select("id, email, role")
      .single();

    if (error) throw error;

    void logAction(
      role === "banned" ? "admin_user_banned" : "admin_role_changed",
      auth.userId,
      { targetUserId: userId, newRole: role },
      request
    );

    return NextResponse.json({ data });
  } catch (err) {
    console.error("[PATCH /api/v1/admin/users/[userId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update user" } },
      { status: 500 }
    );
  }
}
