import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

interface RouteContext {
  params: Promise<{ id: string }>;
}

function decodeCursor(cursor: string): string | null {
  try { return Buffer.from(cursor, "base64url").toString("utf8"); }
  catch { return null; }
}
function encodeCursor(publishedAt: string): string {
  return Buffer.from(publishedAt).toString("base64url");
}

/**
 * GET /api/v1/journalists/[id]
 *
 * Returns a journalist's public profile, their recent articles,
 * and whether the current user follows them (auth optional).
 *
 * Query params:  limit, cursor
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  try {
    const { id } = await params;
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "10"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;

    const supabase = createServiceClient();

    // Journalist profile
    const { data: journalist, error } = await supabase
      .from("journalists")
      .select("id, name, bio, avatar_url, byline_match, is_verified, follower_count")
      .eq("id", id)
      .single();

    if (error?.code === "PGRST116") {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "Journalist not found" } },
        { status: 404 }
      );
    }
    if (error) throw error;

    // Articles by this journalist
    let articleQuery = supabase
      .from("articles")
      .select("id, title, description, thumbnail_url, published_at, source_name, category, url, country_code, view_count, journalist_id")
      .eq("journalist_id", id)
      .order("published_at", { ascending: false })
      .limit(limit + 1);

    if (cursor) {
      const publishedAt = decodeCursor(cursor);
      if (publishedAt) articleQuery = articleQuery.lt("published_at", publishedAt);
    }

    const { data: rows, error: aErr } = await articleQuery;
    if (aErr) throw aErr;

    const allRows = rows ?? [];
    const hasMore = allRows.length > limit;
    const page = allRows.slice(0, limit);

    const articles = page.map((r) => ({
      id: r.id as string,
      title: r.title as string,
      summary: (r.description as string | null) ?? null,
      imageUrl: (r.thumbnail_url as string | null) ?? null,
      publishedAt: r.published_at as string,
      sourceName: (r.source_name as string) ?? "Unknown",
      category: (r.category as string) ?? "general",
      url: r.url as string,
      countryCode: (r.country_code as string | null) ?? null,
      journalistId: id,
      journalistName: journalist.name as string,
    }));

    const nextCursor = hasMore
      ? encodeCursor(page[page.length - 1].published_at as string)
      : null;

    // Is the current user following?
    let isFollowing = false;
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: follow } = await supabase
        .from("journalist_follows")
        .select("id")
        .eq("journalist_id", id)
        .eq("user_id", user.id)
        .single();
      isFollowing = !!follow;
    }

    return NextResponse.json(
      {
        data: {
          journalist: {
            id: journalist.id as string,
            name: journalist.name as string,
            bio: (journalist.bio as string | null) ?? null,
            avatarUrl: (journalist.avatar_url as string | null) ?? null,
            isVerified: (journalist.is_verified as boolean),
            followerCount: (journalist.follower_count as number),
          },
          isFollowing,
          articles,
          nextCursor,
        },
      },
      { headers: { "Cache-Control": "public, s-maxage=300, stale-while-revalidate=900" } }
    );
  } catch (err) {
    console.error("[GET /api/v1/journalists/[id]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch journalist" } },
      { status: 500 }
    );
  }
}
