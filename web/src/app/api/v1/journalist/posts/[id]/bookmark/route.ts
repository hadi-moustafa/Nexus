import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

interface RouteContext {
  params: Promise<{ id: string }>;
}

/**
 * GET /api/v1/journalist/posts/[id]/bookmark
 * Returns { data: { isBookmarked: boolean } }
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const supabase = createServiceClient();

  const { data } = await supabase
    .from("post_bookmarks")
    .select("id")
    .eq("user_id", auth.userId)
    .eq("post_id", id)
    .maybeSingle();

  return NextResponse.json({ data: { isBookmarked: !!data } });
}

/**
 * POST /api/v1/journalist/posts/[id]/bookmark
 * Toggles bookmark. Returns { data: { isBookmarked: boolean, action: "bookmarked" | "unbookmarked" } }
 */
export async function POST(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  const { id } = await params;
  const supabase = createServiceClient();

  // Check if post exists
  const { data: post } = await supabase
    .from("journalist_posts")
    .select("id")
    .eq("id", id)
    .maybeSingle();

  if (!post) {
    return NextResponse.json(
      { error: { code: "NOT_FOUND", message: "Post not found" } },
      { status: 404 }
    );
  }

  // Check existing bookmark
  const { data: existing } = await supabase
    .from("post_bookmarks")
    .select("id")
    .eq("user_id", auth.userId)
    .eq("post_id", id)
    .maybeSingle();

  if (existing) {
    const { error } = await supabase
      .from("post_bookmarks")
      .delete()
      .eq("id", existing.id);

    if (error) {
      console.error("[POST bookmark] delete:", error);
      return NextResponse.json(
        { error: { code: "INTERNAL_ERROR", message: error.message } },
        { status: 500 }
      );
    }
    return NextResponse.json({ data: { isBookmarked: false, action: "unbookmarked" } });
  }

  const { error } = await supabase
    .from("post_bookmarks")
    .insert({ user_id: auth.userId, post_id: id });

  if (error) {
    console.error("[POST bookmark] insert:", error);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: error.message } },
      { status: 500 }
    );
  }
  return NextResponse.json({ data: { isBookmarked: true, action: "bookmarked" } }, { status: 201 });
}
