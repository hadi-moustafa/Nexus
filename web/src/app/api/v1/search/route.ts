import { type NextRequest } from "next/server";
import { searchArticles } from "@/lib/db/articles";

/**
 * GET /api/v1/search
 *
 * Full-text style article search (ilike on title + description).
 *
 * Query params:
 *   q         string   required — search term
 *   limit     number   (default 20, max 50)
 *   cursor    string   pagination cursor
 *   category  string   optional category filter
 *   language  string   optional language filter (en, fr, ar)
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const q = searchParams.get("q")?.trim();

    if (!q) {
      return Response.json(
        { error: { code: "VALIDATION_ERROR", message: "Query parameter 'q' is required" } },
        { status: 400 }
      );
    }

    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;
    const category = searchParams.get("category") ?? undefined;
    const language = searchParams.get("language") ?? undefined;

    const { articles, nextCursor } = await searchArticles({ query: q, limit, cursor, category, language });

    return Response.json({ data: articles, meta: { nextCursor } });
  } catch (err) {
    console.error("[GET /api/v1/search]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Search failed" } },
      { status: 500 }
    );
  }
}
