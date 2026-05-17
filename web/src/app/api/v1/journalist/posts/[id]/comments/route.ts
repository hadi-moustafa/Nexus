import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { rateLimit, rateLimitResponse } from "@/lib/rate-limit";

interface RouteContext {
  params: Promise<{ id: string }>;
}

/**
 * GET /api/v1/journalist/posts/[id]/comments
 * Paginated comments for a post, newest first (held comments excluded).
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  try {
    const { id: postId } = await params;
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;

    const supabase = createServiceClient();

    let query = supabase
      .from("post_comments")
      .select(`id, body, created_at, author_id, users ( display_name, avatar_url )`)
      .eq("post_id", postId)
      .eq("is_held", false)
      .order("created_at", { ascending: false })
      .limit(limit + 1);

    if (cursor) query = query.lt("id", cursor);

    const { data, error } = await query;
    if (error) throw error;

    const rows = data ?? [];
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    const comments = page.map((row) => {
      const author = row.users as unknown as Record<string, unknown> | null;
      return {
        id: row.id as string,
        postId,
        body: row.body as string,
        createdAt: row.created_at as string,
        authorId: row.author_id as string,
        authorName: (author?.display_name as string | null) ?? "Anonymous",
        authorAvatar: (author?.avatar_url as string | null) ?? null,
      };
    });

    return NextResponse.json({
      data: comments,
      meta: { nextCursor: hasMore ? (page[page.length - 1].id as string) : null },
    });
  } catch (err) {
    console.error("[GET /api/v1/journalist/posts/[id]/comments]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch comments" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/journalist/posts/[id]/comments
 * Post a comment on a journalist post. Requires auth.
 * Body: { body: string }
 */
export async function POST(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  const rl = rateLimit(`post_comment:${auth.userId}`, 5, 60 * 1000);
  if (!rl.ok) return rateLimitResponse(rl.resetAt) as NextResponse;

  try {
    const { id: postId } = await params;
    const { body } = await request.json();

    if (!body || typeof body !== "string" || body.trim().length === 0) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "body is required" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("post_comments")
      .insert({ post_id: postId, author_id: auth.userId, body: body.trim().slice(0, 1000) })
      .select("id, body, created_at, author_id")
      .single();

    if (error) throw error;

    return NextResponse.json(
      {
        data: {
          id: data.id,
          postId,
          body: data.body,
          createdAt: data.created_at,
          authorId: data.author_id,
          authorName: "You",
          authorAvatar: null,
        },
      },
      { status: 201 }
    );
  } catch (err) {
    console.error("[POST /api/v1/journalist/posts/[id]/comments]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to post comment" } },
      { status: 500 }
    );
  }
}
