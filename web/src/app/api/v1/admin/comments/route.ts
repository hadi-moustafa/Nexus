import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/comments
 * Returns comments for moderation. Admin only.
 *
 * Query params:
 *   source  "articles" | "posts" | "all"  (default "articles")
 *   filter  "all" | "flagged" | "held"    (default "all")
 *   limit   number  (default 50)
 *   cursor  string  (comment id)
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { searchParams } = request.nextUrl;
    const source = searchParams.get("source") ?? "articles";
    const filter = searchParams.get("filter") ?? "all";
    const limit = Math.min(Number(searchParams.get("limit") ?? "50"), 100);
    const cursor = searchParams.get("cursor") ?? undefined;
    const supabase = createServiceClient();

    const fetchTable = async (table: "comments" | "post_comments", refKey: "article_id" | "post_id") => {
      let query = supabase
        .from(table)
        .select(`id, body, created_at, is_held, is_flagged, ${refKey}, author_id, users ( display_name, email )`)
        .order("created_at", { ascending: false })
        .limit(limit + 1);

      if (filter === "flagged") query = query.eq("is_flagged", true);
      if (filter === "held") query = query.eq("is_held", true);
      if (cursor) query = query.lt("id", cursor);

      const { data, error } = await query;
      if (error) throw error;
      const rows = data ?? [];
      const hasMore = rows.length > limit;
      return { rows: rows.slice(0, limit).map((r) => ({ ...r, source: table === "comments" ? "article" : "post" })), hasMore };
    };

    if (source === "articles") {
      const { rows, hasMore } = await fetchTable("comments", "article_id");
      return NextResponse.json({ data: rows, meta: { nextCursor: hasMore ? rows[rows.length - 1].id : null } });
    }

    if (source === "posts") {
      const { rows, hasMore } = await fetchTable("post_comments", "post_id");
      return NextResponse.json({ data: rows, meta: { nextCursor: hasMore ? rows[rows.length - 1].id : null } });
    }

    // source === "all" — merge both tables
    const [a, p] = await Promise.all([
      fetchTable("comments", "article_id"),
      fetchTable("post_comments", "post_id"),
    ]);
    const merged = [...a.rows, ...p.rows]
      .sort((x, y) => new Date(y.created_at as string).getTime() - new Date(x.created_at as string).getTime())
      .slice(0, limit);

    return NextResponse.json({ data: merged, meta: { nextCursor: null } });
  } catch (err) {
    console.error("[GET /api/v1/admin/comments]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch comments" } },
      { status: 500 }
    );
  }
}
