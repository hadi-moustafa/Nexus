import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { getArticles } from "@/lib/db/articles";

/**
 * GET /api/v1/feed
 *
 * Returns a paginated article feed across all sources and languages.
 * - Authenticated (web or mobile): "For You" tab applies user topic preferences.
 * - Anonymous: general unfiltered feed.
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;
    const categoryParam = searchParams.get("category") ?? undefined;
    const languageParam = searchParams.get("language") ?? undefined;

    let topics: string[] | undefined;

    // Personalise the "For You" tab using the authenticated user's topic prefs.
    // requireAuth returns a NextResponse (401) when not authenticated — we treat
    // that as anonymous and skip personalisation rather than returning an error.
    if (!categoryParam && !languageParam) {
      const auth = await requireAuth(request);
      if (!(auth instanceof NextResponse)) {
        const supabase = createServiceClient();
        const { data: prefs } = await supabase
          .from("user_preferences")
          .select("topics")
          .eq("user_id", auth.userId)
          .single();

        if (prefs?.topics && (prefs.topics as string[]).length > 0) {
          topics = prefs.topics as string[];
        }
      }
    }

    const { articles, nextCursor } = await getArticles({
      limit,
      cursor,
      category: categoryParam,
      language: languageParam,
      topics,
    });

    return Response.json({ data: articles, meta: { nextCursor } });
  } catch (err) {
    console.error("[GET /api/v1/feed]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch feed" } },
      { status: 500 }
    );
  }
}
