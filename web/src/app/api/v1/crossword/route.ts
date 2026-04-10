import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

// XP rewards
const XP_COMPLETE = 100;
const XP_FAST_BONUS = 30; // awarded if completed in under 3 minutes

/**
 * POST /api/v1/crossword
 *
 * Records a completed crossword puzzle, awards XP, updates streak.
 * One completion per user per day (enforced by DB unique constraint).
 *
 * Body: { timeSeconds: number }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { timeSeconds } = await request.json();

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const today = new Date().toISOString().slice(0, 10);

    // Check if already completed today
    const { data: existing } = await supabase
      .from("crossword_results")
      .select("id, xp_earned")
      .eq("user_id", auth.userId)
      .eq("puzzle_date", today)
      .single();

    if (existing) {
      return NextResponse.json(
        { error: { code: "ALREADY_COMPLETED", message: "Already completed today's crossword" } },
        { status: 409 }
      );
    }

    const isFast = typeof timeSeconds === "number" && timeSeconds < 180;
    const xpEarned = XP_COMPLETE + (isFast ? XP_FAST_BONUS : 0);

    // Streak logic
    const { data: stats } = await supabase
      .from("user_stats")
      .select("current_streak, longest_streak, total_xp, last_activity_date")
      .eq("user_id", auth.userId)
      .single();

    const lastDate = (stats?.last_activity_date as string | null) ?? null;
    const currentStreak = (stats?.current_streak as number) ?? 0;

    let newStreak: number;
    if (!lastDate) {
      newStreak = 1;
    } else {
      const diffDays = Math.round(
        (new Date(today).getTime() - new Date(lastDate).getTime()) / (1000 * 60 * 60 * 24)
      );
      newStreak = diffDays === 1 ? currentStreak + 1 : diffDays === 0 ? currentStreak : 1;
    }

    // Insert crossword result
    const { error: insertErr } = await supabase.from("crossword_results").insert({
      user_id: auth.userId,
      puzzle_date: today,
      completed: true,
      xp_earned: xpEarned,
      time_seconds: timeSeconds ?? null,
    });

    if (insertErr) {
      if (insertErr.code === "23505") {
        return NextResponse.json(
          { error: { code: "ALREADY_COMPLETED", message: "Already completed today's crossword" } },
          { status: 409 }
        );
      }
      throw insertErr;
    }

    // Update user_stats
    await supabase.from("user_stats").upsert(
      {
        user_id: auth.userId,
        total_xp: ((stats?.total_xp as number) ?? 0) + xpEarned,
        current_streak: newStreak,
        longest_streak: Math.max((stats?.longest_streak as number) ?? 0, newStreak),
        last_activity_date: today,
      },
      { onConflict: "user_id" }
    );

    return NextResponse.json({
      data: { xpEarned, isFast, newStreak },
    });
  } catch (err) {
    console.error("[POST /api/v1/crossword]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to record crossword result" } },
      { status: 500 }
    );
  }
}

/**
 * GET /api/v1/crossword
 *
 * Returns whether the current user has completed today's crossword.
 * Auth optional — unauthenticated users always get alreadyCompleted: false.
 */
export async function GET(_request: NextRequest) {
  try {
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ data: { alreadyCompleted: false } });
    }

    const today = new Date().toISOString().slice(0, 10);
    const { data } = await supabase
      .from("crossword_results")
      .select("id, xp_earned, time_seconds")
      .eq("user_id", user.id)
      .eq("puzzle_date", today)
      .single();

    return NextResponse.json({
      data: { alreadyCompleted: !!data, xpEarned: data?.xp_earned ?? 0, timeSeconds: data?.time_seconds ?? null },
    });
  } catch (err) {
    console.error("[GET /api/v1/crossword]", err);
    return NextResponse.json({ data: { alreadyCompleted: false } });
  }
}
