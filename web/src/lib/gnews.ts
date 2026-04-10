import { createClient } from "@supabase/supabase-js";

// ---------------------------------------------------------------------------
// GNews ingestion — ported from supabase/functions/fetch-news/index.ts
//
// Changes from the Deno version:
//   - Deno.env.get()  →  process.env
//   - jsr:@supabase/supabase-js@2  →  @supabase/supabase-js (already in package.json)
//   - Deno.serve() handler  →  plain exported async function
//   - CORS headers removed (this runs server-side, not in a browser context)
// ---------------------------------------------------------------------------

const CATEGORIES = [
  "general",
  "world",
  "business",
  "technology",
  "science",
  "sports",
  "entertainment",
  "health",
] as const;

export interface IngestResult {
  totalInserted: number;
  categoriesProcessed: number;
  errors: string[];
}

/**
 * Fetches the latest headlines from GNews across all categories and upserts
 * them into the `articles` table using the service role key (bypasses RLS).
 *
 * Called by:
 *   - /api/cron/fetch-news  (automated, hourly)
 *   - /api/v1/internal/fetch-news  (manual trigger from dashboard)
 */
export async function fetchAndIngestAll(): Promise<IngestResult> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const gnewsApiKey = process.env.GNEWS_API_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error(
      "Missing required env vars: NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY"
    );
  }
  if (!gnewsApiKey) {
    throw new Error("Missing required env var: GNEWS_API_KEY");
  }

  // Service role client — bypasses RLS for upserts.
  // Never expose this client to the browser.
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  let totalInserted = 0;
  const errors: string[] = [];

  for (const category of CATEGORIES) {
    const url =
      `https://gnews.io/api/v4/top-headlines?category=${category}&lang=en&max=10&apikey=${gnewsApiKey}`;

    let res: Response;
    try {
      res = await fetch(url);
    } catch (err) {
      errors.push(`Network error for '${category}': ${String(err)}`);
      continue;
    }

    if (!res.ok) {
      errors.push(`GNews error for '${category}': ${res.status} ${res.statusText}`);
      continue;
    }

    const json = await res.json();
    const articles: GNewsArticle[] = json.articles ?? [];

    if (articles.length === 0) continue;

    const rows = articles.map((a) => ({
      title: a.title,
      description: a.description ?? null,
      content: a.content ?? null,
      url: a.url,
      thumbnail_url: a.image ?? null,
      published_at: a.publishedAt,
      source_name: a.source?.name ?? "Unknown",
      category,
      language: a.lang ?? "en",
    }));

    const { error } = await supabase
      .from("articles")
      .upsert(rows, { onConflict: "url", ignoreDuplicates: true });

    if (error) {
      errors.push(`DB upsert error for '${category}': ${error.message}`);
    } else {
      totalInserted += rows.length;
    }
  }

  return {
    totalInserted,
    categoriesProcessed: CATEGORIES.length,
    errors,
  };
}

// ---------------------------------------------------------------------------
// GNews API response shape
// ---------------------------------------------------------------------------
interface GNewsArticle {
  title: string;
  description?: string;
  content?: string;
  url: string;
  image?: string;
  publishedAt: string;
  lang?: string;
  source?: { name?: string; url?: string };
}
