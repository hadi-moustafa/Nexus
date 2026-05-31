import { NextRequest, NextResponse } from "next/server";
import { requireAdminApi } from "@/lib/admin";
import { createServiceClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";

/**
 * DELETE /api/v1/admin/posts/[id]
 * Admin deletes any journalist post.
 */
export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const guard = await requireAdminApi(req);
  if (guard instanceof NextResponse) return guard;
  const admin = guard;

  const { id } = await params;
  const supabase = createServiceClient();

  const { error } = await supabase.from("journalist_posts").delete().eq("id", id);

  if (error) {
    console.error("[DELETE /api/v1/admin/posts/[id]]", error);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: error.message } },
      { status: 500 }
    );
  }

  void logAction("admin_post_deleted", admin.userId, { postId: id }, req);
  return new NextResponse(null, { status: 204 });
}
