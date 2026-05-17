import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { rateLimit, rateLimitResponse } from "@/lib/rate-limit";
import { logAction } from "@/lib/audit";

/**
 * GET /api/v1/journalist/posts
 *
 * Public feed of journalist posts, newest first.
 * Query params: limit (max 50), cursor (post id), journalist_id
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;
    const journalistId = searchParams.get("journalist_id") ?? undefined;

    const supabase = createServiceClient();

    let query = supabase
      .from("journalist_posts")
      .select(`
        id, title, body, image_url, category, view_count,
        comment_count, reaction_count, created_at, updated_at, journalist_id,
        journalists ( name, avatar_url, is_verified )
      `)
      .order("created_at", { ascending: false })
      .limit(limit + 1);

    if (journalistId) query = query.eq("journalist_id", journalistId);
    if (cursor) query = query.lt("id", cursor);

    const { data, error } = await query;
    if (error) throw error;

    const rows = data ?? [];
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    const posts = page.map((r) => {
      const j = r.journalists as unknown as Record<string, unknown> | null;
      return {
        id: r.id as string,
        journalistId: r.journalist_id as string,
        journalistName: (j?.name as string | null) ?? "Unknown",
        journalistAvatarUrl: (j?.avatar_url as string | null) ?? null,
        isVerified: (j?.is_verified as boolean) ?? false,
        title: r.title as string,
        body: r.body as string,
        imageUrl: (r.image_url as string | null) ?? null,
        category: (r.category as string) ?? "general",
        viewCount: (r.view_count as number) ?? 0,
        commentCount: (r.comment_count as number) ?? 0,
        reactionCount: (r.reaction_count as number) ?? 0,
        createdAt: r.created_at as string,
        updatedAt: r.updated_at as string,
      };
    });

    return NextResponse.json(
      { data: posts, meta: { nextCursor: hasMore ? page[page.length - 1].id : null } },
      { headers: { "Cache-Control": "public, s-maxage=30, stale-while-revalidate=120" } }
    );
  } catch (err) {
    console.error("[GET /api/v1/journalist/posts]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch posts" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/journalist/posts
 *
 * Creates a new journalist post. Requires role = journalist.
 * Body: { title, body, image_url?, category? }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  // 10 posts per hour
  const rl = rateLimit(`journalist_post:${auth.userId}`, 10, 60 * 60 * 1000);
  if (!rl.ok) return rateLimitResponse(rl.resetAt) as NextResponse;

  try {
    const supabase = createServiceClient();

    const { data: userRow } = await supabase
      .from("users")
      .select("role")
      .eq("id", auth.userId)
      .single();

    if (!userRow || !["journalist", "admin"].includes(userRow.role as string)) {
      return NextResponse.json(
        { error: { code: "FORBIDDEN", message: "Journalist role required" } },
        { status: 403 }
      );
    }

    const { data: journalistRow } = await supabase
      .from("journalists")
      .select("id")
      .eq("user_id", auth.userId)
      .single();

    if (!journalistRow) {
      return NextResponse.json(
        { error: { code: "FORBIDDEN", message: "No journalist profile linked to your account" } },
        { status: 403 }
      );
    }

    const { title, body, image_url, category } = await request.json();

    if (!title?.trim() || !body?.trim()) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "title and body are required" } },
        { status: 400 }
      );
    }

    const { data, error } = await supabase
      .from("journalist_posts")
      .insert({
        journalist_id: journalistRow.id,
        title: title.trim().slice(0, 200),
        body: body.trim().slice(0, 10000),
        image_url: image_url ?? null,
        category: category ?? "general",
      })
      .select("id, title, body, image_url, category, view_count, comment_count, reaction_count, created_at, updated_at, journalist_id")
      .single();

    if (error) throw error;

    void logAction("journalist_post_created", auth.userId, { postId: data.id, title: data.title }, request);

    // Auto-award prolific badge if 50+ posts
    const { count } = await supabase
      .from("journalist_posts")
      .select("id", { count: "exact", head: true })
      .eq("journalist_id", journalistRow.id);

    if ((count ?? 0) >= 50) {
      await supabase.from("journalist_badges").upsert(
        { journalist_id: journalistRow.id, badge_type: "prolific" },
        { onConflict: "journalist_id,badge_type", ignoreDuplicates: true }
      );
    }

    return NextResponse.json({ data }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/journalist/posts]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to create post" } },
      { status: 500 }
    );
  }
}
