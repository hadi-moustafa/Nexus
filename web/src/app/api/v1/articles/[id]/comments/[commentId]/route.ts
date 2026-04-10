import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

interface RouteContext {
  params: Promise<{ id: string; commentId: string }>;
}

/**
 * DELETE /api/v1/articles/[id]/comments/[commentId]
 * Deletes a comment. Authors can delete their own comments (within 10 min per RLS).
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { commentId } = await params;
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { error } = await supabase
      .from("comments")
      .delete()
      .eq("id", commentId)
      .eq("author_id", auth.userId);

    if (error) throw error;

    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/articles/[id]/comments/[commentId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to delete comment" } },
      { status: 500 }
    );
  }
}
