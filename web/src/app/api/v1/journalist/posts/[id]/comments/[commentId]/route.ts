import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

interface RouteContext {
  params: Promise<{ id: string; commentId: string }>;
}

/**
 * DELETE /api/v1/journalist/posts/[id]/comments/[commentId]
 * Delete a comment. Author can delete own; admin/journalist-owner can delete any.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { id: postId, commentId } = await params;
    const supabase = createServiceClient();

    const { data: comment } = await supabase
      .from("post_comments")
      .select("author_id, post_id")
      .eq("id", commentId)
      .eq("post_id", postId)
      .single();

    if (!comment) {
      return NextResponse.json({ error: { code: "NOT_FOUND", message: "Comment not found" } }, { status: 404 });
    }

    // Allow: own comment, admin, or journalist who owns the post
    const isOwner = comment.author_id === auth.userId;
    if (!isOwner) {
      const { data: userRow } = await supabase.from("users").select("role").eq("id", auth.userId).single();
      const isAdmin = userRow?.role === "admin";

      if (!isAdmin) {
        const { data: journalistRow } = await supabase
          .from("journalists")
          .select("id")
          .eq("user_id", auth.userId)
          .single();
        const { data: post } = await supabase
          .from("journalist_posts")
          .select("journalist_id")
          .eq("id", postId)
          .single();

        if (!journalistRow || !post || post.journalist_id !== journalistRow.id) {
          return NextResponse.json({ error: { code: "FORBIDDEN", message: "Not allowed" } }, { status: 403 });
        }
      }
    }

    const { error } = await supabase.from("post_comments").delete().eq("id", commentId);
    if (error) throw error;

    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/journalist/posts/[id]/comments/[commentId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to delete comment" } },
      { status: 500 }
    );
  }
}
