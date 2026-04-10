import { type NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth";
import { getUserStats } from "@/lib/db/users";

/**
 * GET /api/v1/user/stats
 * Returns the authenticated user's gamification stats.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const stats = await getUserStats(auth.userId);
    if (!stats) {
      return NextResponse.json({
        data: {
          totalXp: 0,
          currentStreak: 0,
          longestStreak: 0,
          quizzesCompleted: 0,
          perfectScores: 0,
          articlesRead: 0,
        },
      });
    }
    return NextResponse.json({ data: stats });
  } catch (err) {
    console.error("[GET /api/v1/user/stats]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch stats" } },
      { status: 500 }
    );
  }
}
