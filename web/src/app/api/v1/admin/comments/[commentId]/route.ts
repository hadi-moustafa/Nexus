import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

interface RouteContext {
  params: Promise<{ commentId: string }>;
}

/**
 * PATCH /api/v1/admin/comments/[commentId]
 * Update moderation flags on a comment. Admin only.
 *
 * Body (all optional): { is_held?: boolean, is_flagged?: boolean }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { commentId } = await params;
    const body = await request.json();
    const patch: Record<string, unknown> = {};

    if (typeof body.is_held === "boolean") patch.is_held = body.is_held;
    if (typeof body.is_flagged === "boolean") patch.is_flagged = body.is_flagged;

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { data, error } = await supabase
      .from("comments")
      .update(patch)
      .eq("id", commentId)
      .select("id, is_held, is_flagged")
      .single();

    if (error) throw error;

    return NextResponse.json({ data });
  } catch (err) {
    console.error("[PATCH /api/v1/admin/comments/[commentId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update comment" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/admin/comments/[commentId]
 * Hard-delete a comment. Admin only.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { commentId } = await params;
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { error } = await supabase.from("comments").delete().eq("id", commentId);
    if (error) throw error;

    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/admin/comments/[commentId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to delete comment" } },
      { status: 500 }
    );
  }
}
