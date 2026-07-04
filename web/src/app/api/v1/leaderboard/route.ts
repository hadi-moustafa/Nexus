import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

/**
 * GET /api/v1/leaderboard
 *
 * Returns the top users by XP. Tries the `leaderboard` materialized view first,
 * then falls back to a live query on user_stats + users if the view doesn't exist.
 * When the DB is empty (no quiz activity yet) a set of mock entries is returned
 * so the page always has something to display during development.
 *
 * Query params:
 *   limit   number  (default 50, max 100)
 *   offset  number  (default 0)
 */

interface LeaderboardEntry {
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  totalXp: number;
  rank: number;
}

const MOCK_ENTRIES: LeaderboardEntry[] = [
  { userId: "mock-1",  displayName: "Layla Hassan",    avatarUrl: null, totalXp: 9420, rank: 1 },
  { userId: "mock-2",  displayName: "Omar Khalil",     avatarUrl: null, totalXp: 8175, rank: 2 },
  { userId: "mock-3",  displayName: "Nour Saleh",      avatarUrl: null, totalXp: 7650, rank: 3 },
  { userId: "mock-4",  displayName: "Karim Mansour",   avatarUrl: null, totalXp: 6890, rank: 4 },
  { userId: "mock-5",  displayName: "Sara Nasser",     avatarUrl: null, totalXp: 6210, rank: 5 },
  { userId: "mock-6",  displayName: "Ali Farouk",      avatarUrl: null, totalXp: 5740, rank: 6 },
  { userId: "mock-7",  displayName: "Dina Aziz",       avatarUrl: null, totalXp: 5120, rank: 7 },
  { userId: "mock-8",  displayName: "Tarek Yousef",    avatarUrl: null, totalXp: 4580, rank: 8 },
  { userId: "mock-9",  displayName: "Rana Ibrahim",    avatarUrl: null, totalXp: 3990, rank: 9 },
  { userId: "mock-10", displayName: "Jad Nassar",      avatarUrl: null, totalXp: 3410, rank: 10 },
  { userId: "mock-11", displayName: "Maya Khoury",     avatarUrl: null, totalXp: 2870, rank: 11 },
  { userId: "mock-12", displayName: "Ziad Hamdan",     avatarUrl: null, totalXp: 2340, rank: 12 },
  { userId: "mock-13", displayName: "Hana Moussa",     avatarUrl: null, totalXp: 1810, rank: 13 },
  { userId: "mock-14", displayName: "Rami Awad",       avatarUrl: null, totalXp: 1290, rank: 14 },
  { userId: "mock-15", displayName: "Lina Chaaban",    avatarUrl: null, totalXp:  750, rank: 15 },
];

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = request.nextUrl;
    const limit  = Math.min(Number(searchParams.get("limit")  ?? "50"), 100);
    const offset = Number(searchParams.get("offset") ?? "0");

    const supabase = createServiceClient();

    // ── 1. Try the materialized view ──────────────────────────────────────
    let entries: LeaderboardEntry[] = [];
    const { data: viewRows, error: viewError } = await supabase
      .from("leaderboard")
      .select("user_id, display_name, avatar_url, total_xp, rank")
      .order("rank", { ascending: true })
      .range(offset, offset + limit - 1);

    if (!viewError && viewRows && viewRows.length > 0) {
      entries = viewRows.map((r, i) => ({
        userId:      r.user_id     as string,
        displayName: (r.display_name as string | null) ?? "Anonymous",
        avatarUrl:   (r.avatar_url  as string | null) ?? null,
        totalXp:     r.total_xp    as number,
        rank:        (r.rank        as number | null) ?? offset + i + 1,
      }));
    }

    // ── 2. Fallback: live query on user_stats + users ─────────────────────
    if (entries.length === 0) {
      const { data: statsRows } = await supabase
        .from("user_stats")
        .select("user_id, total_xp, users ( display_name, avatar_url )")
        .order("total_xp", { ascending: false })
        .range(offset, offset + limit - 1);

      if (statsRows && statsRows.length > 0) {
        entries = statsRows.map((r, i) => {
          const u = r.users as Record<string, unknown> | null;
          return {
            userId:      r.user_id as string,
            displayName: (u?.display_name as string | null) ?? "Anonymous",
            avatarUrl:   (u?.avatar_url   as string | null) ?? null,
            totalXp:     (r.total_xp      as number) ?? 0,
            rank:        offset + i + 1,
          };
        });
      }
    }

    // ── 3. Final fallback: mock data (dev / empty DB) ─────────────────────
    if (entries.length === 0) {
      const slice = MOCK_ENTRIES.slice(offset, offset + limit);
      entries = slice;
    }

    // ── Current user's rank ───────────────────────────────────────────────
    let myRank: { rank: number; totalXp: number } | null = null;
    const auth = await requireAuth(request);
    if (!(auth instanceof NextResponse)) {
      // Try the view first, then user_stats
      const { data: mine } = await supabase
        .from("leaderboard")
        .select("rank, total_xp")
        .eq("user_id", auth.userId)
        .maybeSingle();

      if (mine) {
        myRank = { rank: mine.rank as number, totalXp: mine.total_xp as number };
      } else {
        const { data: statsRow } = await supabase
          .from("user_stats")
          .select("total_xp")
          .eq("user_id", auth.userId)
          .maybeSingle();

        if (statsRow) {
          const { count } = await supabase
            .from("user_stats")
            .select("*", { count: "exact", head: true })
            .gt("total_xp", (statsRow.total_xp as number) ?? 0);

          myRank = {
            rank:    (count ?? 0) + 1,
            totalXp: (statsRow.total_xp as number) ?? 0,
          };
        }
      }
    }

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
