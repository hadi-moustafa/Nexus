import { createClient } from "@supabase/supabase-js";

// ---------------------------------------------------------------------------
// Guardian Open Platform ingestion
//
// Fetches latest articles from The Guardian across mapped sections and
// upserts them into the `articles` table using the service role key.
//
// Guardian sections → our DB categories:
//   general     ← uk-news | us-news | politics | australia-news
//   world       ← world | global-development
//   business    ← business | money
//   technology  ← technology
//   science     ← science
//   sports      ← sport
//   entertainment ← culture | film | music | tv-and-radio
//   health      ← lifeandstyle | society | environment
// ---------------------------------------------------------------------------

const SECTION_MAP: Record<string, string[]> = {
  general:       ["uk-news", "us-news", "politics", "australia-news"],
  world:         ["world", "global-development"],
  business:      ["business", "money"],
  technology:    ["technology"],
  science:       ["science"],
  sports:        ["sport"],
  entertainment: ["culture", "film", "music", "tv-and-radio"],
  health:        ["lifeandstyle", "society", "environment"],
};

// Build a flat list of { section, category } pairs to query
const QUERIES = Object.entries(SECTION_MAP).flatMap(([category, sections]) =>
  sections.map((section) => ({ section, category }))
);

export interface GuardianIngestResult {
  totalInserted: number;
  sectionsProcessed: number;
  errors: string[];
}

interface GuardianArticle {
  webTitle: string;
  webUrl: string;
  webPublicationDate: string;
  fields?: {
    trailText?: string;
    thumbnail?: string;
  };
}

/**
 * Fetches latest articles from The Guardian and upserts them into `articles`.
 * Runs with service role key — never call from browser context.
 */
export async function fetchAndIngestFromGuardian(): Promise<GuardianIngestResult> {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const apiKey = process.env.GUARDIAN_API_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Missing required env vars: NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }
  if (!apiKey) {
    throw new Error("Missing required env var: GUARDIAN_API_KEY");
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  let totalInserted = 0;
  const errors: string[] = [];

  for (const { section, category } of QUERIES) {
    const url =
      `https://content.guardianapis.com/search` +
      `?api-key=${apiKey}` +
      `&section=${section}` +
      `&show-fields=trailText,thumbnail` +
      `&page-size=10` +
      `&order-by=newest`;

    let res: Response;
    try {
      res = await fetch(url);
    } catch (err) {
      errors.push(`Network error for '${section}': ${String(err)}`);
      continue;
    }

    if (!res.ok) {
      errors.push(`Guardian error for '${section}': ${res.status} ${res.statusText}`);
      continue;
    }

    const json = await res.json();
    const articles: GuardianArticle[] = json.response?.results ?? [];

    if (articles.length === 0) continue;

    const rows = articles.map((a) => ({
      title: a.webTitle,
      description: a.fields?.trailText ?? null,
      content: null, // Guardian body is HTML — skip for now
      url: a.webUrl,
      thumbnail_url: a.fields?.thumbnail ?? null,
      published_at: a.webPublicationDate,
      source_name: "The Guardian",
      category,
      language: "en",
    }));

    const { error } = await supabase
      .from("articles")
      .upsert(rows, { onConflict: "url", ignoreDuplicates: true });

    if (error) {
      errors.push(`DB upsert error for '${section}': ${error.message}`);
    } else {
      totalInserted += rows.length;
    }
  }

  return {
    totalInserted,
    sectionsProcessed: QUERIES.length,
    errors,
  };
}
