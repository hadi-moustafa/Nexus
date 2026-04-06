import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import type { Article } from "@/types";

// ---------------------------------------------------------------------------
// Row mapping
// Maps a raw Supabase DB row (snake_case) to the canonical Article type
// (camelCase). This is the single place where column names are translated —
// never in components or route handlers.
// ---------------------------------------------------------------------------
function rowToArticle(row: Record<string, unknown>): Article {
  return {
    id: row.id as string,
    title: row.title as string,
    summary: (row.summary as string | null) ?? null,
    content: (row.content as string | null) ?? null,
    url: row.url as string,
    imageUrl: (row.image_url as string | null) ?? null,
    publishedAt: row.published_at as string,
    sourceId: (row.source_id as string) ?? "",
    category: (row.category as string) ?? "General",
    language: (row.language as string) ?? "en",
    region: (row.region as string | null) ?? null,
  };
}

// ---------------------------------------------------------------------------
// Cursor helpers
// Cursor = base64url-encoded published_at timestamp.
// Simple and collision-tolerant enough for a news feed.
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
// Used by the web TrendingFeed server component (direct DB call, no HTTP hop).
// ---------------------------------------------------------------------------
export async function getTrendingArticles(opts: {
  limit?: number;
  cursor?: string;
} = {}): Promise<{ articles: Article[]; nextCursor: string | null }> {
  const { limit = 10, cursor } = opts;

  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  let query = supabase
    .from("articles")
    .select("*")
    .order("published_at", { ascending: false })
    .limit(limit + 1); // +1 to detect if there is a next page

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
// Paginated article list with optional category filter.
// Used by /api/v1/articles route handler.
// ---------------------------------------------------------------------------
export async function getArticles(opts: {
  limit?: number;
  cursor?: string;
  category?: string;
} = {}): Promise<{ articles: Article[]; nextCursor: string | null }> {
  const { limit = 20, cursor, category } = opts;

  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  let query = supabase
    .from("articles")
    .select("*")
    .order("published_at", { ascending: false })
    .limit(limit + 1);

  if (category) {
    query = query.eq("category", category);
  }

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
// Used by /api/v1/articles/[id] route handler.
// Returns null when the article does not exist.
// ---------------------------------------------------------------------------
export async function getArticleById(id: string): Promise<Article | null> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const { data, error } = await supabase
    .from("articles")
    .select("*")
    .eq("id", id)
    .single();

  if (error) {
    if (error.code === "PGRST116") return null; // row not found
    throw error;
  }

  return data ? rowToArticle(data as Record<string, unknown>) : null;
}
