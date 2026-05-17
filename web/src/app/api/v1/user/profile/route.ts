import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { logAction } from "@/lib/audit";

/**
 * PATCH /api/v1/user/profile
 * Updates the authenticated user's display name and/or avatar URL.
 * Body: { displayName?: string, avatarUrl?: string }
 * At least one field is required.
 */
export async function PATCH(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const body = await request.json();
    const displayName = typeof body.displayName === "string" ? body.displayName.trim() : null;
    const avatarUrl = typeof body.avatarUrl === "string" ? body.avatarUrl.trim() : null;

    if (!displayName && !avatarUrl) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "At least one of displayName or avatarUrl is required" } },
        { status: 400 }
      );
    }

    if (displayName !== null && (displayName.length === 0 || displayName.length > 50)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Display name must be 1–50 characters" } },
        { status: 400 }
      );
    }

    const updates: Record<string, string> = {};
    if (displayName) updates.display_name = displayName;
    if (avatarUrl) updates.avatar_url = avatarUrl;

    const supabase = createServiceClient();

    const { error } = await supabase
      .from("users")
      .update(updates)
      .eq("id", auth.userId);

    if (error) throw error;

    void logAction("profile_updated", auth.userId, { displayName, avatarUrl }, request);
    return NextResponse.json({ data: { displayName, avatarUrl } });
  } catch (err) {
    console.error("[PATCH /api/v1/user/profile]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update profile" } },
      { status: 500 }
    );
  }
}
