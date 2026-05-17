import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { rateLimit, rateLimitResponse } from "@/lib/rate-limit";

interface RouteContext {
  params: Promise<{ id: string }>;
}

/**
 * GET /api/v1/articles/[id]/comments
 * Returns visible comments for an article, newest first.
 *
 * Query params:
 *   limit   number  (default 20, max 50)
 *   cursor  string  opaque cursor (comment id for keyset pagination)
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  try {
    const { id: articleId } = await params;
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;

    const supabase = createServiceClient();

    let query = supabase
      .from("comments")
      .select(`
        id,
        body,
        created_at,
        edited_at,
        author_id,
        users ( display_name, avatar_url )
      `)
      .eq("article_id", articleId)
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
        body: row.body as string,
        createdAt: row.created_at as string,
        editedAt: (row.edited_at as string | null) ?? null,
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
    console.error("[GET /api/v1/articles/[id]/comments]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch comments" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/articles/[id]/comments
 * Posts a new comment. Requires authentication.
 *
 * Body: { body: string }
 */
export async function POST(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  // 5 comments per user per minute
  const rl = rateLimit(`comment:${auth.userId}`, 5, 60 * 1000);
  if (!rl.ok) return rateLimitResponse(rl.resetAt) as NextResponse;

  try {
    const { id: articleId } = await params;
    const { body } = await request.json();

    if (!body || typeof body !== "string" || body.trim().length === 0) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Comment body is required" } },
        { status: 400 }
      );
    }

    const trimmed = body.trim().slice(0, 1000); // max 1000 chars

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("comments")
      .insert({
        article_id: articleId,
        author_id: auth.userId,
        body: trimmed,
      })
      .select("id, body, created_at, author_id")
      .single();

    if (error) throw error;

    return NextResponse.json(
      {
        data: {
          id: data.id,
          body: data.body,
          createdAt: data.created_at,
          editedAt: null,
          authorId: data.author_id,
          authorName: "You",
          authorAvatar: null,
        },
      },
      { status: 201 }
    );
  } catch (err) {
    console.error("[POST /api/v1/articles/[id]/comments]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to post comment" } },
      { status: 500 }
    );
  }
}
