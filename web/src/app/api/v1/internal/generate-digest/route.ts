import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { generateDigest } from "@/lib/gemini";

/**
 * POST /api/v1/internal/generate-digest
 *
 * Generates today's AI digest using Gemini and stores it in the digests table.
 * Protected by a shared secret (INTERNAL_CRON_SECRET) — intended to be called
 * by a scheduled cron job or Supabase Edge Function.
 *
 * Body (optional): { cohortKey?: string, language?: "en"|"ar"|"fr" }
 * Defaults to cohortKey="en", language="en".
 */
export async function POST(request: NextRequest) {
  // Verify cron secret
  const secret = request.headers.get("x-internal-secret");
  if (!process.env.INTERNAL_CRON_SECRET || secret !== process.env.INTERNAL_CRON_SECRET) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const body = await request.json().catch(() => ({}));
    const cohortKey: string = body.cohortKey ?? "en";
    const language: "en" | "ar" | "fr" = body.language ?? "en";

    const today = new Date().toISOString().slice(0, 10);

    const supabase = createServiceClient();

    // Check if digest already generated today for this cohort
    const { data: existing } = await supabase
      .from("digests")
      .select("id")
      .eq("cohort_key", cohortKey)
      .eq("digest_date", today)
      .single();

    if (existing) {
      return NextResponse.json({ data: { message: "Digest already generated today", id: existing.id } });
    }

    // Fetch top articles published today (or last 24 h)
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { data: articles, error: aErr } = await supabase
      .from("articles")
      .select("id, title, description, url, category, language")
      .gte("published_at", since)
      .eq("language", language)
      .order("view_count", { ascending: false })
      .limit(10);

    if (aErr) throw aErr;

    if (!articles || articles.length === 0) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "No articles found for digest" } },
        { status: 404 }
      );
    }

    // Generate with Gemini
    const digest = await generateDigest(
      articles.map((a) => ({
        id: a.id as string,
        title: a.title as string,
        description: (a.description as string | null),
        url: a.url as string,
        category: (a.category as string) ?? "general",
      })),
      language
    );

    // Store in DB
    const { data: inserted, error: insertErr } = await supabase
      .from("digests")
      .insert({
        cohort_key: cohortKey,
        digest_date: today,
        introduction: digest.introduction,
        stories: digest.stories,
        article_count: digest.stories.length,
      })
      .select("id")
      .single();

    if (insertErr) throw insertErr;

    return NextResponse.json({ data: { id: inserted.id, articleCount: digest.stories.length } });
  } catch (err) {
    console.error("[POST /api/v1/internal/generate-digest]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to generate digest" } },
      { status: 500 }
    );
  }
}
