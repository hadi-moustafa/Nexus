import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { rateLimit } from "@/lib/rate-limit";

interface RouteContext {
  params: Promise<{ id: string }>;
}

/**
 * POST /api/v1/articles/[id]/view
 *
 * Tracks that the authenticated user viewed an article.
 * - Increments article.view_count by 1.
 * - Increments user_stats.articles_read by 1.
 * - Rate-limited: one counted view per user per article per hour.
 *
 * Returns 204 always (best-effort tracking, never blocks the client).
 */
export async function POST(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  const { id: articleId } = await params;

  // Silently skip if this user already viewed this article recently
  const rl = rateLimit(`view:${auth.userId}:${articleId}`, 1, 60 * 60 * 1000);
  if (!rl.ok) return new NextResponse(null, { status: 204 });

  try {
    const supabase = createServiceClient();

    const [articleRes, statsRes] = await Promise.all([
      supabase.from("articles").select("view_count").eq("id", articleId).single(),
      supabase.from("user_stats").select("articles_read").eq("user_id", auth.userId).single(),
    ]);

    await Promise.all([
      supabase
        .from("articles")
        .update({ view_count: ((articleRes.data?.view_count as number) ?? 0) + 1 })
        .eq("id", articleId),
      supabase
        .from("user_stats")
        .upsert(
          { user_id: auth.userId, articles_read: ((statsRes.data?.articles_read as number) ?? 0) + 1 },
          { onConflict: "user_id" }
        ),
    ]);
  } catch (err) {
    console.error("[POST /api/v1/articles/[id]/view]", err);
    // Best-effort — don't surface tracking errors to the client
  }

  return new NextResponse(null, { status: 204 });
}
