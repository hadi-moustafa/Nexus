import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { getArticles } from "@/lib/db/articles";

// Arabic category slug used in the mobile app
const ARABIC_CATEGORY = "العربية";

/**
 * GET /api/v1/feed
 *
 * Returns a paginated article feed across all sources and languages.
 * - Authenticated (web or mobile): "For You" tab applies user topic preferences.
 * - Anonymous: general unfiltered feed.
 * - Arabic language/category: Premium only.
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;
    const categoryParam = searchParams.get("category") ?? undefined;
    const languageParam = searchParams.get("language") ?? undefined;

    const isArabicRequest = languageParam === "ar" || categoryParam === ARABIC_CATEGORY;

    let topics: string[] | undefined;
    let resolvedUserId: string | null = null;

    const auth = await requireAuth(request);
    const isAuthenticated = !(auth instanceof NextResponse);
    if (isAuthenticated) resolvedUserId = auth.userId;

    // Arabic feed — premium users only
    if (isArabicRequest) {
      if (!isAuthenticated) {
        return NextResponse.json(
          { error: { code: "FORBIDDEN", message: "Arabic feed requires a Premium subscription." } },
          { status: 403 }
        );
      }
      const supabase = createServiceClient();
      const { data: sub } = await supabase
        .from("subscriptions")
        .select("status")
        .eq("user_id", auth.userId)
        .in("status", ["active", "trialing"])
        .maybeSingle();

      if (!sub) {
        return NextResponse.json(
          { error: { code: "FORBIDDEN", message: "Arabic feed is a Premium feature. Upgrade to access it." } },
          { status: 403 }
        );
      }
    }

    // Personalise the "For You" tab using the authenticated user's topic prefs.
    if (!categoryParam && !languageParam && isAuthenticated) {
      const supabase = createServiceClient();
      const { data: prefs } = await supabase
        .from("user_preferences")
        .select("topics")
        .eq("user_id", resolvedUserId!)
        .single();

      if (prefs?.topics && (prefs.topics as string[]).length > 0) {
        topics = prefs.topics as string[];
      }
    }

    let { articles, nextCursor } = await getArticles({
      limit,
      cursor,
      category: categoryParam,
      language: languageParam,
      topics,
    });

    // "For You" personalisation returned nothing — fall back to the full feed so
    // the tab never appears empty on a fresh install or sparse DB.
    if (articles.length === 0 && topics && topics.length > 0 && !categoryParam && !languageParam && !cursor) {
      ({ articles, nextCursor } = await getArticles({ limit, cursor }));
    }

    return Response.json({ data: articles, meta: { nextCursor } });
  } catch (err) {
    console.error("[GET /api/v1/feed]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch feed" } },
      { status: 500 }
    );
  }
}
