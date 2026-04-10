import { createClient } from "@supabase/supabase-js";

// ---------------------------------------------------------------------------
// Arabic News API ingestion (RapidAPI)
//
// Sources:
//   Al Jazeera Arabic  → GET /aljazeera
//   CNN Arabic         → GET /cnnarabic
//   RT Arabic          → GET /rtarabic
//
// All three share the same host/key. Response shapes differ slightly:
//   Al Jazeera / CNN Arabic: { results: [{ headline, underHeadline, content, date, image, url }] }
//   RT Arabic:               { results: [{ source, title, content, image, url }] }
//
// Dates come as Arabic-locale strings (e.g. "الجمعة، 10 ابريل / نيسان 2026")
// or are absent. We fall back to Date.now() when parsing fails.
// ---------------------------------------------------------------------------

const BASE_URL = "https://arabic-news-api.p.rapidapi.com";

const SOURCES: { endpoint: string; sourceName: string; category: string }[] = [
  { endpoint: "aljazeera", sourceName: "الجزيرة",     category: "world"   },
  { endpoint: "cnnarabic", sourceName: "CNN عربي",    category: "general" },
  { endpoint: "rtarabic",  sourceName: "RT عربي",     category: "world"   },
];

export interface ArabicIngestResult {
  totalInserted: number;
  sourcesProcessed: number;
  errors: string[];
}

// Arabic month name → numeric month index (0-based)
const ARABIC_MONTHS: Record<string, number> = {
  "يناير": 0, "كانون الثاني": 0,
  "فبراير": 1, "شباط": 1,
  "مارس": 2, "آذار": 2,
  "ابريل": 3, "نيسان": 3, "أبريل": 3,
  "مايو": 4, "أيار": 4,
  "يونيو": 5, "حزيران": 5,
  "يوليو": 6, "تموز": 6,
  "اغسطس": 7, "أغسطس": 7, "آب": 7,
  "سبتمبر": 8, "أيلول": 8,
  "أكتوبر": 9, "تشرين الأول": 9,
  "نوفمبر": 10, "تشرين الثاني": 10,
  "ديسمبر": 11, "كانون الأول": 11,
};

/**
 * Parses an Arabic-locale date string such as
 * "الجمعة، 10 ابريل / نيسان 2026" into an ISO timestamp.
 * Returns now() if parsing fails.
 */
function parseArabicDate(raw: string | undefined | null): string {
  if (!raw) return new Date().toISOString();

  // Try native Date first (works for ISO strings)
  const native = new Date(raw);
  if (!isNaN(native.getTime())) return native.toISOString();

  // Pattern: "…، DD MonthName / AltMonthName YYYY"
  const match = raw.match(/(\d{1,2})\s+([\u0600-\u06FFa-zA-Z\s]+?)(?:\s*\/.*?)?\s+(\d{4})/);
  if (match) {
    const day   = parseInt(match[1], 10);
    const month = ARABIC_MONTHS[match[2].trim()];
    const year  = parseInt(match[3], 10);
    if (month !== undefined && !isNaN(day) && !isNaN(year)) {
      return new Date(year, month, day, 12, 0, 0).toISOString();
    }
  }

  return new Date().toISOString();
}

interface RawArticle {
  headline?: string;
  title?: string;
  underHeadline?: string;
  content?: string;
  date?: string;
  image?: string;
  url: string;
}

/**
 * Fetches the latest articles from all three Arabic sources and upserts
 * them into the `articles` table with language = 'ar'.
 */
export async function fetchAndIngestArabic(): Promise<ArabicIngestResult> {
  const supabaseUrl   = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  const rapidApiKey   = process.env.RAPIDAPI_KEY;

  if (!supabaseUrl || !serviceRoleKey) {
    throw new Error("Missing required env vars: NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
  }
  if (!rapidApiKey) {
    throw new Error("Missing required env var: RAPIDAPI_KEY");
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  let totalInserted = 0;
  const errors: string[] = [];

  for (const { endpoint, sourceName, category } of SOURCES) {
    let res: Response;
    try {
      res = await fetch(`${BASE_URL}/${endpoint}`, {
        headers: {
          "x-rapidapi-host": "arabic-news-api.p.rapidapi.com",
          "x-rapidapi-key": rapidApiKey,
          "Content-Type": "application/json",
        },
      });
    } catch (err) {
      errors.push(`Network error for '${endpoint}': ${String(err)}`);
      continue;
    }

    if (!res.ok) {
      errors.push(`API error for '${endpoint}': ${res.status} ${res.statusText}`);
      continue;
    }

    const json = await res.json();
    const articles: RawArticle[] = json.results ?? [];

    if (articles.length === 0) continue;

    const rows = articles
      .filter((a) => a.url)
      .map((a) => ({
        title:         a.headline ?? a.title ?? "(بدون عنوان)",
        description:   a.underHeadline || null,
        content:       a.content || null,
        url:           a.url,
        thumbnail_url: a.image ?? null,
        published_at:  parseArabicDate(a.date),
        source_name:   sourceName,
        category,
        language:      "ar",
      }));

    if (rows.length === 0) continue;

    const { error } = await supabase
      .from("articles")
      .upsert(rows, { onConflict: "url", ignoreDuplicates: true });

    if (error) {
      errors.push(`DB upsert error for '${endpoint}': ${error.message}`);
    } else {
      totalInserted += rows.length;
    }
  }

  return {
    totalInserted,
    sourcesProcessed: SOURCES.length,
    errors,
  };
}
