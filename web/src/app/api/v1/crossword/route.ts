import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

// XP rewards
const XP_COMPLETE = 100;
const XP_FAST_BONUS = 30; // awarded if completed in under 3 minutes

// Default daily puzzle — replace rows in the `crosswords` DB table to go fully dynamic.
const DEFAULT_PUZZLE = {
  answer: [
    ["O", "R", "B", "I", "T"],
    [null, "O", "I", null, "R"],
    ["P", "U", "L", "S", "E"],
    [null, "S", "L", null, "E"],
    ["N", "E", "X", "U", "S"],
  ] as (string | null)[][],
  clues: [
    { id: "1A", number: 1, direction: "across", row: 0, col: 0, length: 5, clue: "Earth's path around the sun; also a space station module (5)" },
    { id: "3A", number: 3, direction: "across", row: 2, col: 0, length: 5, clue: "Heartbeat rhythm; a throbbing sensation of energy (5)" },
    { id: "5A", number: 5, direction: "across", row: 4, col: 0, length: 5, clue: "Central point where things converge; this app's name! (5)" },
    { id: "2D", number: 2, direction: "down",   row: 0, col: 1, length: 5, clue: "To awaken or stir up; anagram of EUROS (5)" },
    { id: "4D", number: 4, direction: "down",   row: 0, col: 2, length: 4, clue: "A banknote, a statement, or a bird's beak (4)" },
    { id: "6D", number: 6, direction: "down",   row: 0, col: 4, length: 5, clue: "Tall plants with trunks; they line boulevards (5)" },
  ],
  cellNumbers: { "0-0": 1, "0-1": 2, "0-2": 4, "0-4": 6, "2-0": 3, "4-0": 5 } as Record<string, number>,
};

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

    const supabase = createServiceClient();

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
 * Returns today's puzzle + whether the current user has already completed it.
 * Auth optional — unauthenticated users always get alreadyCompleted: false.
 *
 * Response: { data: { alreadyCompleted, xpEarned, timeSeconds, puzzle } }
 */
export async function GET(_request: NextRequest) {
  try {
    const supabase = createServiceClient();
    const today = new Date().toISOString().slice(0, 10);

    // Try to load a puzzle from the crosswords table (date-matched or latest).
    // Falls back to DEFAULT_PUZZLE if none exist yet.
    let puzzle = DEFAULT_PUZZLE;
    const { data: dbPuzzle } = await supabase
      .from("crosswords")
      .select("answer, clues, cell_numbers")
      .lte("puzzle_date", today)
      .order("puzzle_date", { ascending: false })
      .limit(1)
      .maybeSingle();

    if (dbPuzzle?.answer && dbPuzzle?.clues) {
      puzzle = {
        answer: dbPuzzle.answer as (string | null)[][],
        clues: dbPuzzle.clues as typeof DEFAULT_PUZZLE.clues,
        cellNumbers: (dbPuzzle.cell_numbers as Record<string, number>) ?? DEFAULT_PUZZLE.cellNumbers,
      };
    }

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return NextResponse.json({ data: { alreadyCompleted: false, puzzle } });
    }

    const { data } = await supabase
      .from("crossword_results")
      .select("id, xp_earned, time_seconds")
      .eq("user_id", user.id)
      .eq("puzzle_date", today)
      .single();

    return NextResponse.json({
      data: {
        alreadyCompleted: !!data,
        xpEarned: data?.xp_earned ?? 0,
        timeSeconds: data?.time_seconds ?? null,
        puzzle,
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/crossword]", err);
    return NextResponse.json({ data: { alreadyCompleted: false, puzzle: DEFAULT_PUZZLE } });
  }
}
