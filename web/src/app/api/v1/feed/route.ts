import { type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { getArticles } from "@/lib/db/articles";

/**
 * GET /api/v1/feed
 *
 * Returns a paginated article feed across all sources and languages.
 * - Authenticated: "For You" tab also applies the user's preferred topics.
 * - Anonymous: general feed unfiltered.
 *
 * Query params:
 *   limit     number   (default 20, max 50)
 *   cursor    string   opaque pagination cursor
 *   category  string   tab filter — "lebanon" triggers keyword search,
 *                      any other value matches the DB category column
 *   language  string   explicit language filter, e.g. "ar" for Arabic tab.
 *                      When absent, ALL languages are returned (including Arabic).
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;
    const categoryParam = searchParams.get("category") ?? undefined;
    // Explicit language param — only set when a language-specific tab is active.
    // Never derived from user prefs so that Arabic articles always show in "For You".
    const languageParam = searchParams.get("language") ?? undefined;

    let topics: string[] | undefined;

    // Load user topics (not language!) for the "For You" personalised tab.
    if (!categoryParam && !languageParam) {
      const cookieStore = await cookies();
      const supabase = createClient(cookieStore);
      const { data: { user } } = await supabase.auth.getUser();

      if (user) {
        const { data: prefs } = await supabase
          .from("user_preferences")
          .select("topics")
          .eq("user_id", user.id)
          .single();

        if (prefs && prefs.topics && (prefs.topics as string[]).length > 0) {
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
