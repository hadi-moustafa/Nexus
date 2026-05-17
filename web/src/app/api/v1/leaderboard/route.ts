import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/leaderboard
 *
 * Returns the top users by XP from the leaderboard materialized view.
 * Also returns the current user's rank if authenticated.
 *
 * Query params:
 *   limit   number  (default 50, max 100)
 *   offset  number  (default 0, for page-based navigation)
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "50"), 100);
    const offset = Number(searchParams.get("offset") ?? "0");

    const supabase = createServiceClient();

    const { data: rows, error } = await supabase
      .from("leaderboard")
      .select("user_id, display_name, avatar_url, total_xp, rank")
      .order("rank", { ascending: true })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    // Current user's rank (best-effort)
    let myRank: { rank: number; totalXp: number } | null = null;
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: mine } = await supabase
        .from("leaderboard")
        .select("rank, total_xp")
        .eq("user_id", user.id)
        .single();

      if (mine) {
        myRank = { rank: mine.rank as number, totalXp: mine.total_xp as number };
      }
    }

    const entries = (rows ?? []).map((r) => ({
      userId: r.user_id as string,
      displayName: (r.display_name as string | null) ?? "Anonymous",
      avatarUrl: (r.avatar_url as string | null) ?? null,
      totalXp: r.total_xp as number,
      rank: r.rank as number,
    }));

    return NextResponse.json(
      { data: entries, meta: { myRank } },
      { headers: { "Cache-Control": "public, s-maxage=120, stale-while-revalidate=600" } }
    );
  } catch (err) {
    console.error("[GET /api/v1/leaderboard]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch leaderboard" } },
      { status: 500 }
    );
  }
}
