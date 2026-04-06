// DEPRECATED — This Supabase Edge Function has been migrated to:
//   web/src/lib/gnews.ts          (core ingestion logic)
//   web/src/app/api/cron/fetch-news/route.ts  (automated cron trigger)
//   web/src/app/api/v1/internal/fetch-news/route.ts  (manual dashboard trigger)
//
// Do not deploy or modify this file. It is kept for reference only.

import { createClient } from "jsr:@supabase/supabase-js@2";

// These are automatically injected by Supabase into every Edge Function
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
// This one we set manually via secrets
const GNEWS_API_KEY = Deno.env.get("GNEWS_API_KEY")!;

const CATEGORIES = [
  "general", "world", "business", "technology",
  "science", "sports", "entertainment", "health",
];

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Authorization, Content-Type",
      },
    });
  }

  try {
    // Use the service role key to bypass RLS for writes
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    let totalInserted = 0;
    const errors: string[] = [];

    for (const category of CATEGORIES) {
      const url =
        `https://gnews.io/api/v4/top-headlines?category=${category}&lang=en&max=10&apikey=${GNEWS_API_KEY}`;

      const res = await fetch(url);

      if (!res.ok) {
        errors.push(`GNews error for '${category}': ${res.status} ${res.statusText}`);
        continue;
      }

      const json = await res.json();
      const articles: any[] = json.articles ?? [];

      if (articles.length === 0) continue;

      const rows = articles.map((a) => ({
        title: a.title,
        summary: a.description,
        content: a.content,
        url: a.url,
        image_url: a.image,
        published_at: a.publishedAt,
        source_id: a.source?.name ?? "Unknown",
        category: category,
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

    return new Response(
      JSON.stringify({
        success: true,
        totalInserted,
        categoriesProcessed: CATEGORIES.length,
        ...(errors.length > 0 && { errors }),
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
