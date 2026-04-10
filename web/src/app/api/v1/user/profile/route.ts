import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

/**
 * PATCH /api/v1/user/profile
 * Updates the authenticated user's display name.
 * Body: { displayName: string }
 */
export async function PATCH(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const body = await request.json();
    const displayName = typeof body.displayName === "string" ? body.displayName.trim() : "";

    if (!displayName || displayName.length > 50) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Display name must be 1–50 characters" } },
        { status: 400 }
      );
    }

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { error } = await supabase
      .from("users")
      .update({ display_name: displayName })
      .eq("id", auth.userId);

    if (error) throw error;

    return NextResponse.json({ data: { displayName } });
  } catch (err) {
    console.error("[PATCH /api/v1/user/profile]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update profile" } },
      { status: 500 }
    );
  }
}
