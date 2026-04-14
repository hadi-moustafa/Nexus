import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

/**
 * GET /api/v1/digest
 *
 * Returns today's digest for the authenticated user.
 * Requires an active subscription (status = 'active' | 'trialing').
 *
 * If no digest exists for today it auto-generates one:
 *   - With Gemini if GEMINI_API_KEY is set
 *   - Otherwise falls back to a plain summary built from article titles/descriptions
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    // Use service client throughout — no cookie lock contention
    const supabase = createServiceClient();

    // Verify premium subscription
    const { data: sub } = await supabase
      .from("subscriptions")
      .select("status")
      .eq("user_id", auth.userId)
      .single();

    const isPremium = sub?.status === "active" || sub?.status === "trialing";
    if (!isPremium) {
      return NextResponse.json(
        { error: { code: "FORBIDDEN", message: "Premium subscription required" } },
        { status: 403 }
      );
    }

    // Get user's preferred language for cohort selection
    const { data: prefs } = await supabase
      .from("user_preferences")
      .select("preferred_language")
      .eq("user_id", auth.userId)
      .single();

    const language = (prefs?.preferred_language as string) ?? "en";
    const today = new Date().toISOString().slice(0, 10);

    // Try user's language cohort first, then fall back to "en"
    const { data: digest } = await supabase
      .from("digests")
      .select("id, cohort_key, digest_date, introduction, stories, article_count, generated_at")
      .eq("digest_date", today)
      .in("cohort_key", [language, "en"])
      .order("cohort_key", { ascending: false })
      .limit(1)
      .single();

    if (digest) {
      return NextResponse.json({ data: digest });
    }

    // No digest yet — generate on demand
    // Try last 24h first, fall back to last 7 days, then just the most recent articles
    const lang = language === "ar" || language === "fr" ? language : "en";

    async function fetchArticles(since: string, language: string) {
      return (await supabase
        .from("articles")
        .select("id, title, description, url, category, language")
        .gte("published_at", since)
        .eq("language", language)
        .order("published_at", { ascending: false })
        .limit(10)
      ).data ?? [];
    }

    const since24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const since7d  = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    let effectiveArticles = await fetchArticles(since24h, lang);

    // Widen to 7 days if sparse
    if (effectiveArticles.length < 3) {
      effectiveArticles = await fetchArticles(since7d, lang);
    }

    // Fall back to English if still sparse
    if (effectiveArticles.length < 3 && lang !== "en") {
      effectiveArticles = await fetchArticles(since24h, "en");
      if (effectiveArticles.length < 3) {
        effectiveArticles = await fetchArticles(since7d, "en");
      }
    }

    // Last resort: newest 10 articles regardless of language or date
    if (effectiveArticles.length === 0) {
      effectiveArticles = (await supabase
        .from("articles")
        .select("id, title, description, url, category, language")
        .order("published_at", { ascending: false })
        .limit(10)
      ).data ?? [];
    }

    if (!effectiveArticles || effectiveArticles.length === 0) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "No articles available to generate a digest" } },
        { status: 404 }
      );
    }

    let generatedDigest: { introduction: string; stories: unknown[] };

    if (process.env.GEMINI_API_KEY) {
      // Full AI generation
      const { generateDigest } = await import("@/lib/gemini");
      generatedDigest = await generateDigest(
        effectiveArticles.map((a) => ({
          id: a.id as string,
          title: a.title as string,
          description: (a.description as string | null),
          url: a.url as string,
          category: (a.category as string) ?? "general",
        })),
        lang
      );
    } else {
      // Plain fallback — no AI
      generatedDigest = {
        introduction: `Here are today's top ${effectiveArticles.length} stories from around the world.`,
        stories: effectiveArticles.map((a) => ({
          title: a.title as string,
          summary: (a.description as string | null) ?? "No summary available.",
          category: (a.category as string) ?? "general",
          url: a.url as string,
          articleId: a.id as string,
        })),
      };
    }

    // Persist so subsequent requests are fast
    // Upsert handles race conditions (two users hitting digest at the same time)
    const { data: inserted } = await supabase
      .from("digests")
      .upsert(
        {
          cohort_key: lang,
          digest_date: today,
          introduction: generatedDigest.introduction,
          stories: generatedDigest.stories,
          article_count: generatedDigest.stories.length,
        },
        { onConflict: "cohort_key,digest_date" }
      )
      .select("id, cohort_key, digest_date, introduction, stories, article_count, generated_at")
      .single();

    return NextResponse.json({ data: inserted ?? { ...generatedDigest, digest_date: today, cohort_key: lang, article_count: generatedDigest.stories.length, generated_at: new Date().toISOString() } });
  } catch (err) {
    console.error("[GET /api/v1/digest]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch digest" } },
      { status: 500 }
    );
  }
}
