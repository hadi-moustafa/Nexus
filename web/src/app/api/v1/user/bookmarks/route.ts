import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

/**
 * GET /api/v1/user/bookmarks
 * Returns the authenticated user's bookmarks, newest first.
 *
 * Query params:
 *   limit   number   (default 20, max 50)
 *   cursor  string   opaque pagination cursor (bookmark id)
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;

    const supabase = createServiceClient();

    let query = supabase
      .from("bookmarks")
      .select(`
        id,
        article_id,
        created_at,
        articles (
          id, title, description, content, url, thumbnail_url,
          published_at, source_id, source_name, category, language,
          country_code, ai_summary, view_count
        )
      `)
      .eq("user_id", auth.userId)
      .order("created_at", { ascending: false })
      .limit(limit + 1);

    if (cursor) query = query.lt("id", cursor);

    const { data, error } = await query;
    if (error) throw error;

    const rows = data ?? [];
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    const bookmarks = page.map((row) => {
      const a = row.articles as unknown as Record<string, unknown> | null;
      return {
        id: row.id as string,
        articleId: row.article_id as string,
        createdAt: row.created_at as string,
        article: a
          ? {
              id: a.id,
              title: a.title,
              summary: a.description ?? null,
              content: a.content ?? null,
              url: a.url,
              imageUrl: a.thumbnail_url ?? null,
              publishedAt: a.published_at,
              sourceId: (a.source_id as string) ?? "",
              sourceName: (a.source_name as string) ?? "Unknown",
              category: (a.category as string) ?? "general",
              language: (a.language as string) ?? "en",
              countryCode: (a.country_code as string | null) ?? null,
              aiSummary: (a.ai_summary as string | null) ?? null,
              viewCount: (a.view_count as number) ?? 0,
            }
          : null,
      };
    });

    return NextResponse.json({
      data: bookmarks,
      meta: {
        nextCursor: hasMore ? (page[page.length - 1].id as string) : null,
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/user/bookmarks]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch bookmarks" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/user/bookmarks
 * Adds an article to the user's bookmarks.
 *
 * Body: { articleId: string }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { articleId } = await request.json();
    if (!articleId || typeof articleId !== "string") {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "articleId is required" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("bookmarks")
      .insert({ user_id: auth.userId, article_id: articleId })
      .select("id, article_id, created_at")
      .single();

    if (error) {
      // Unique constraint violation — already bookmarked
      if (error.code === "23505") {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "Article already bookmarked" } },
          { status: 409 }
        );
      }
      throw error;
    }

    return NextResponse.json(
      { data: { id: data.id, articleId: data.article_id, createdAt: data.created_at } },
      { status: 201 }
    );
  } catch (err) {
    console.error("[POST /api/v1/user/bookmarks]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to add bookmark" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/user/bookmarks
 * Removes an article from the user's bookmarks.
 *
 * Query params: articleId  string
 */
export async function DELETE(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const articleId = request.nextUrl.searchParams.get("articleId");
    if (!articleId) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "articleId query param is required" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    const { error } = await supabase
      .from("bookmarks")
      .delete()
      .eq("user_id", auth.userId)
      .eq("article_id", articleId);

    if (error) throw error;

    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/user/bookmarks]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to remove bookmark" } },
      { status: 500 }
    );
  }
}
