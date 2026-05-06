import { createPublicClient } from "@/lib/supabase/server";
import type { Article } from "@/types";

// ---------------------------------------------------------------------------
// Row mapping
// Actual DB columns (from Supabase schema):
//   id, title, url, source_id (uuid FK), source_name (text), journalist_id,
//   country_code, category, language, ai_summary, description, content,
//   thumbnail_url, published_at, view_count, cached_at, cache_expires_at
// ---------------------------------------------------------------------------
function rowToArticle(row: Record<string, unknown>): Article {
  return {
    id: row.id as string,
    title: row.title as string,
    summary: (row.description as string | null) ?? null,
    content: (row.content as string | null) ?? null,
    url: row.url as string,
    imageUrl: (row.thumbnail_url as string | null) ?? null,
    publishedAt: row.published_at as string,
    sourceId: (row.source_id as string) ?? "",
    sourceName: (row.source_name as string) ?? "Unknown",
    category: (row.category as string) ?? "general",
    language: (row.language as string) ?? "en",
    countryCode: (row.country_code as string | null) ?? null,
    aiSummary: (row.ai_summary as string | null) ?? null,
    viewCount: (row.view_count as number) ?? 0,
    journalistId: (row.journalist_id as string | null) ?? null,
    journalistName: null,
  };
}

// ---------------------------------------------------------------------------
// Cursor helpers — base64url-encoded published_at timestamp
// ---------------------------------------------------------------------------
function encodeCursor(publishedAt: string): string {
  return Buffer.from(publishedAt).toString("base64url");
}

function decodeCursor(cursor: string): string | null {
  try {
    return Buffer.from(cursor, "base64url").toString("utf8");
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// getTrendingArticles
// ---------------------------------------------------------------------------
export async function getTrendingArticles(opts: {
  limit?: number;
  cursor?: string;
} = {}): Promise<{ articles: Article[]; nextCursor: string | null }> {
  const { limit = 10, cursor } = opts;

  const supabase = createPublicClient();

  let query = supabase
    .from("articles")
    .select("*")
    .order("published_at", { ascending: false })
    .limit(limit + 1);

  if (cursor) {
    const publishedAt = decodeCursor(cursor);
    if (publishedAt) query = query.lt("published_at", publishedAt);
  }

  const { data, error } = await query;
  if (error) throw error;

  const rows = data ?? [];
  const hasMore = rows.length > limit;
  const articles = rows.slice(0, limit).map(rowToArticle);

  return {
    articles,
    nextCursor: hasMore ? encodeCursor(articles[articles.length - 1].publishedAt) : null,
  };
}

// ---------------------------------------------------------------------------
// getArticles
// Paginated list with optional filters. Uses public client — articles are
// publicly readable (RLS: USING (true)), no cookie/session needed.
// ---------------------------------------------------------------------------
const LEBANON_FILTER =
  "title.ilike.%Lebanon%,title.ilike.%لبنان%," +
  "description.ilike.%Lebanon%,description.ilike.%لبنان%";

export async function getArticles(opts: {
  limit?: number;
  cursor?: string;
  category?: string;
  countryCode?: string;
  language?: string;
  topics?: string[];
} = {}): Promise<{ articles: Article[]; nextCursor: string | null }> {
  const { limit = 20, cursor, category, countryCode, language, topics } = opts;

  const supabase = createPublicClient();

  let query = supabase
    .from("articles")
    .select("*")
    .order("published_at", { ascending: false })
    .limit(limit + 1);

  if (category === "lebanon") {
    query = query.or(LEBANON_FILTER);
  } else if (category) {
    query = query.eq("category", category);
  }

  if (countryCode) query = query.eq("country_code", countryCode);
  if (language) query = query.eq("language", language);
  if (topics && topics.length > 0) query = query.in("category", topics);

  if (cursor) {
    const publishedAt = decodeCursor(cursor);
    if (publishedAt) query = query.lt("published_at", publishedAt);
  }

  const { data, error } = await query;
  if (error) throw error;

  const rows = data ?? [];
  const hasMore = rows.length > limit;
  const articles = rows.slice(0, limit).map(rowToArticle);

  return {
    articles,
    nextCursor: hasMore ? encodeCursor(articles[articles.length - 1].publishedAt) : null,
  };
}

// ---------------------------------------------------------------------------
// getArticleById
// ---------------------------------------------------------------------------
export async function getArticleById(id: string): Promise<Article | null> {
  const supabase = createPublicClient();

  const { data, error } = await supabase
    .from("articles")
    .select("*")
    .eq("id", id)
    .single();

  if (error) {
    if (error.code === "PGRST116") return null;
    throw error;
  }
  if (!data) return null;

  const article = rowToArticle(data as Record<string, unknown>);

  if (article.journalistId) {
    const { data: journalist } = await supabase
      .from("journalists")
      .select("name")
      .eq("id", article.journalistId)
      .single();

    if (journalist) {
      article.journalistName = journalist.name as string;
    }
  }

  return article;
}

// ---------------------------------------------------------------------------
// searchArticles
// ---------------------------------------------------------------------------
export async function searchArticles(opts: {
  query: string;
  limit?: number;
  cursor?: string;
  category?: string;
  language?: string;
}): Promise<{ articles: Article[]; nextCursor: string | null }> {
  const { query, limit = 20, cursor, category, language } = opts;

  const supabase = createPublicClient();

  let q = supabase
    .from("articles")
    .select("*")
    .or(`title.ilike.%${query}%,description.ilike.%${query}%`)
    .order("published_at", { ascending: false })
    .limit(limit + 1);

  if (category) q = q.eq("category", category);
  if (language) q = q.eq("language", language);

  if (cursor) {
    const publishedAt = decodeCursor(cursor);
    if (publishedAt) q = q.lt("published_at", publishedAt);
  }

  const { data, error } = await q;
  if (error) throw error;

  const rows = data ?? [];
  const hasMore = rows.length > limit;
  const articles = rows.slice(0, limit).map(rowToArticle);

  return {
    articles,
    nextCursor: hasMore ? encodeCursor(articles[articles.length - 1].publishedAt) : null,
  };
}
