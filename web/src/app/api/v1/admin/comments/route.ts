import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/comments
 * Returns comments for moderation. Admin only.
 *
 * Query params:
 *   filter  "all" | "flagged" | "held"  (default "all")
 *   limit   number  (default 50)
 *   cursor  string  (comment id)
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { searchParams } = request.nextUrl;
    const filter = searchParams.get("filter") ?? "all";
    const limit = Math.min(Number(searchParams.get("limit") ?? "50"), 100);
    const cursor = searchParams.get("cursor") ?? undefined;

    const supabase = createServiceClient();

    let query = supabase
      .from("comments")
      .select(`
        id, body, created_at, is_held, is_flagged, article_id, author_id,
        users ( display_name, email )
      `)
      .order("created_at", { ascending: false })
      .limit(limit + 1);

    if (filter === "flagged") query = query.eq("is_flagged", true);
    if (filter === "held") query = query.eq("is_held", true);
    if (cursor) query = query.lt("id", cursor);

    const { data, error } = await query;
    if (error) throw error;

    const rows = data ?? [];
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    return NextResponse.json({
      data: page,
      meta: { nextCursor: hasMore ? page[page.length - 1].id : null },
    });
  } catch (err) {
    console.error("[GET /api/v1/admin/comments]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch comments" } },
      { status: 500 }
    );
  }
}
