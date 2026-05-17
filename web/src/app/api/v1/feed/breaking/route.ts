import { type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/feed/breaking
 *
 * Returns the most recently published articles to populate the breaking
 * news banner. Auth not required — public endpoint.
 *
 * Query params:
 *   limit  number  (default 5, max 10)
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "5"), 10);

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("articles")
      .select("id, title, source_name, published_at, category, thumbnail_url")
      .order("published_at", { ascending: false })
      .limit(limit);

    if (error) throw error;

    const articles = (data ?? []).map((r) => ({
      id: r.id as string,
      title: r.title as string,
      sourceName: (r.source_name as string | null) ?? "Unknown",
      publishedAt: r.published_at as string,
      category: (r.category as string | null) ?? "general",
      imageUrl: (r.thumbnail_url as string | null) ?? null,
    }));

    return Response.json(
      { data: articles },
      {
        headers: {
          "Cache-Control": "public, s-maxage=60, stale-while-revalidate=120",
        },
      }
    );
  } catch (err) {
    console.error("[GET /api/v1/feed/breaking]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch breaking news" } },
      { status: 500 }
    );
  }
}
