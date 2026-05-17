import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";
import { logAction } from "@/lib/audit";

interface RouteContext {
  params: Promise<{ commentId: string }>;
}

/**
 * PATCH /api/v1/admin/comments/[commentId]
 * Update moderation flags on a comment. Admin only.
 *
 * Body (all optional):
 *   { is_held?: boolean, is_flagged?: boolean, source?: "article"|"post", ban_author?: boolean }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { commentId } = await params;
    const body = await request.json();
    const supabase = createServiceClient();

    // Determine which table this comment lives in
    const source = (body.source as string | undefined) ?? "article";
    const table = source === "post" ? "post_comments" : "comments";

    const patch: Record<string, unknown> = {};
    if (typeof body.is_held === "boolean") patch.is_held = body.is_held;
    if (typeof body.is_flagged === "boolean") patch.is_flagged = body.is_flagged;

    let data: Record<string, unknown> | null = null;
    if (Object.keys(patch).length > 0) {
      const { data: updated, error } = await supabase
        .from(table)
        .update(patch)
        .eq("id", commentId)
        .select("id, is_held, is_flagged, author_id")
        .single();
      if (error) throw error;
      data = updated as Record<string, unknown>;
    }

    // Ban the comment author
    if (body.ban_author === true) {
      const authorId = data?.author_id ?? body.author_id;
      if (!authorId) {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "author_id required to ban" } },
          { status: 400 }
        );
      }
      const { error: banErr } = await supabase
        .from("users")
        .update({ role: "banned" })
        .eq("id", authorId);
      if (banErr) throw banErr;

      void logAction("admin_user_banned", auth.userId, { targetUserId: authorId, reason: "comment_ban", commentId }, request);
    }

    if (body.is_flagged === false || body.is_held === false || body.ban_author) {
      void logAction("admin_comment_deleted", auth.userId, { commentId, source, patch }, request);
    }

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
 * Hard-delete a comment from either table. Admin only.
 * Query: source=article|post  (default article)
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { commentId } = await params;
    const source = request.nextUrl.searchParams.get("source") ?? "article";
    const table = source === "post" ? "post_comments" : "comments";
    const supabase = createServiceClient();

    const { error } = await supabase.from(table).delete().eq("id", commentId);
    if (error) throw error;

    void logAction("admin_comment_deleted", auth.userId, { commentId, source, hard: true }, request);
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/admin/comments/[commentId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to delete comment" } },
      { status: 500 }
    );
  }
}
