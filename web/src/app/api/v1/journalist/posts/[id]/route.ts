import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { logAction } from "@/lib/audit";

interface RouteContext {
  params: Promise<{ id: string }>;
}

/**
 * GET /api/v1/journalist/posts/[id]
 * Single post with journalist info. Increments view_count best-effort.
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  try {
    const { id } = await params;
    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("journalist_posts")
      .select(`
        id, title, body, image_url, category, view_count,
        comment_count, reaction_count, created_at, updated_at, journalist_id,
        journalists ( name, avatar_url, is_verified, bio )
      `)
      .eq("id", id)
      .single();

    if (error?.code === "PGRST116") {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "Post not found" } },
        { status: 404 }
      );
    }
    if (error) throw error;

    // Best-effort view count increment
    void supabase
      .from("journalist_posts")
      .update({ view_count: (data.view_count as number) + 1 })
      .eq("id", id);

    const j = data.journalists as unknown as Record<string, unknown> | null;

    return NextResponse.json({
      data: {
        id: data.id as string,
        journalistId: data.journalist_id as string,
        journalistName: (j?.name as string | null) ?? "Unknown",
        journalistAvatarUrl: (j?.avatar_url as string | null) ?? null,
        journalistBio: (j?.bio as string | null) ?? null,
        isVerified: (j?.is_verified as boolean) ?? false,
        title: data.title as string,
        body: data.body as string,
        imageUrl: (data.image_url as string | null) ?? null,
        category: (data.category as string) ?? "general",
        viewCount: (data.view_count as number) ?? 0,
        commentCount: (data.comment_count as number) ?? 0,
        reactionCount: (data.reaction_count as number) ?? 0,
        createdAt: data.created_at as string,
        updatedAt: data.updated_at as string,
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/journalist/posts/[id]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch post" } },
      { status: 500 }
    );
  }
}

/**
 * PATCH /api/v1/journalist/posts/[id]
 * Edit own post. Journalist must own it.
 * Body (all optional): { title?, body?, image_url?, category? }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { id } = await params;
    const supabase = createServiceClient();

    // Verify ownership via journalist profile
    const { data: journalistRow } = await supabase
      .from("journalists")
      .select("id")
      .eq("user_id", auth.userId)
      .single();

    if (!journalistRow) {
      return NextResponse.json(
        { error: { code: "FORBIDDEN", message: "No journalist profile linked" } },
        { status: 403 }
      );
    }

    const { data: post } = await supabase
      .from("journalist_posts")
      .select("journalist_id")
      .eq("id", id)
      .single();

    if (!post || post.journalist_id !== journalistRow.id) {
      return NextResponse.json(
        { error: { code: "FORBIDDEN", message: "You do not own this post" } },
        { status: 403 }
      );
    }

    const body = await request.json();
    const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };
    if (typeof body.title === "string") patch.title = body.title.trim().slice(0, 200);
    if (typeof body.body === "string") patch.body = body.body.trim().slice(0, 10000);
    if ("image_url" in body) patch.image_url = body.image_url ?? null;
    if (typeof body.category === "string") patch.category = body.category;

    const { data, error } = await supabase
      .from("journalist_posts")
      .update(patch)
      .eq("id", id)
      .select("id, title, body, image_url, category, updated_at")
      .single();

    if (error) throw error;
    return NextResponse.json({ data });
  } catch (err) {
    console.error("[PATCH /api/v1/journalist/posts/[id]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update post" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/journalist/posts/[id]
 * Delete own post. Admins can also delete any post.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { id } = await params;
    const supabase = createServiceClient();

    const { data: userRow } = await supabase
      .from("users")
      .select("role")
      .eq("id", auth.userId)
      .single();

    const isAdmin = userRow?.role === "admin";

    if (!isAdmin) {
      const { data: journalistRow } = await supabase
        .from("journalists")
        .select("id")
        .eq("user_id", auth.userId)
        .single();

      if (!journalistRow) {
        return NextResponse.json({ error: { code: "FORBIDDEN", message: "Not allowed" } }, { status: 403 });
      }

      const { data: post } = await supabase
        .from("journalist_posts")
        .select("journalist_id")
        .eq("id", id)
        .single();

      if (!post || post.journalist_id !== journalistRow.id) {
        return NextResponse.json({ error: { code: "FORBIDDEN", message: "You do not own this post" } }, { status: 403 });
      }
    }

    const { error } = await supabase.from("journalist_posts").delete().eq("id", id);
    if (error) throw error;

    void logAction("journalist_post_deleted", auth.userId, { postId: id }, request);
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/journalist/posts/[id]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to delete post" } },
      { status: 500 }
    );
  }
}
