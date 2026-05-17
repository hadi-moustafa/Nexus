import { type NextRequest } from "next/server";
import { getArticles } from "@/lib/db/articles";

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;
    const category = searchParams.get("category") ?? undefined;

    const { articles, nextCursor } = await getArticles({ limit, cursor, category });

    return Response.json(
      { data: articles, meta: { nextCursor } },
      { headers: { "Cache-Control": "public, s-maxage=60, stale-while-revalidate=300" } }
    );
  } catch (err) {
    console.error("[GET /api/v1/articles]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch articles" } },
      { status: 500 }
    );
  }
}
