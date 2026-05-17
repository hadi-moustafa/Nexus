import { type NextRequest } from "next/server";
import { getTrendingArticles } from "@/lib/db/articles";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "10"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;

    const { articles, nextCursor } = await getTrendingArticles({ limit, cursor });

    return Response.json(
      { data: articles, meta: { nextCursor } },
      { headers: { "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300" } }
    );
  } catch (err) {
    console.error("[GET /api/v1/trending]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch trending articles" } },
      { status: 500 }
    );
  }
}
