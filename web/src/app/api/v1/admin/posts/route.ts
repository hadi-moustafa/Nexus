import { NextRequest, NextResponse } from "next/server";
import { requireAdminApi } from "@/lib/admin";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/admin/posts
 * Paginated list of all journalist posts for admin review.
 * Query params: limit, cursor, journalist_id, q (title search)
 */
export async function GET(req: NextRequest) {
  const guard = await requireAdminApi(req);
  if (guard instanceof NextResponse) return guard;

  const { searchParams } = req.nextUrl;
  const limit = Math.min(Number(searchParams.get("limit") ?? "30"), 100);
  const cursor = searchParams.get("cursor") ?? undefined;
  const journalistId = searchParams.get("journalist_id") ?? undefined;
  const q = searchParams.get("q")?.trim() ?? undefined;

  const supabase = createServiceClient();

  let query = supabase
    .from("journalist_posts")
    .select(`
      id, title, body, image_url, category,
      view_count, comment_count, reaction_count,
      created_at, updated_at, journalist_id,
      journalists ( name, is_verified )
    `)
    .order("created_at", { ascending: false })
    .limit(limit + 1);

  if (journalistId) query = query.eq("journalist_id", journalistId);
  if (cursor) query = query.lt("created_at", cursor);
  if (q) query = query.ilike("title", `%${q}%`);

  const { data, error } = await query;

  if (error) {
    console.error("[GET /api/v1/admin/posts]", error);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: error.message } },
      { status: 500 }
    );
  }

  const rows = data ?? [];
  const hasMore = rows.length > limit;
  const page = rows.slice(0, limit);

  const posts = page.map((r) => {
    const j = r.journalists as unknown as Record<string, unknown> | null;
    return {
      id: r.id as string,
      journalistId: r.journalist_id as string,
      journalistName: (j?.name as string | null) ?? "Unknown",
      isVerified: (j?.is_verified as boolean) ?? false,
      title: r.title as string,
      body: (r.body as string).slice(0, 300),
      imageUrl: (r.image_url as string | null) ?? null,
      category: (r.category as string) ?? "general",
      viewCount: (r.view_count as number) ?? 0,
      commentCount: (r.comment_count as number) ?? 0,
      reactionCount: (r.reaction_count as number) ?? 0,
      createdAt: r.created_at as string,
    };
  });

  return NextResponse.json({
    data: posts,
    meta: { nextCursor: hasMore ? page[page.length - 1].created_at : null },
  });
}
