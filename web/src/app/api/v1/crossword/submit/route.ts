import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

const XP_COMPLETE = 100;
const XP_PARTIAL = 40; // at least one word correct

/**
 * POST /api/v1/crossword/submit
 *
 * Validates a crossword solution, awards XP, records result.
 * One submission per user per day (enforced by DB unique constraint).
 *
 * Body: { puzzleDate: string, solution: string[][] }
 *   solution — 5×5 grid of uppercase letters (empty = " ")
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const body = await request.json();
    const { puzzleDate, solution } = body as { puzzleDate?: string; solution?: string[][] };

    if (!puzzleDate || !Array.isArray(solution) || solution.length !== 5) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "puzzleDate and 5×5 solution grid required" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    // Prevent re-submission
    const { data: existing } = await supabase
      .from("crossword_results")
      .select("id, completed, xp_earned")
      .eq("user_id", auth.userId)
      .eq("puzzle_date", puzzleDate)
      .single();

    if (existing) {
      return NextResponse.json({ data: { alreadySubmitted: true, completed: existing.completed, xpEarned: existing.xp_earned } });
    }

    // The answer key for date 2026-04-10 (and every day until we implement date-based rotation)
    // Row 0: O R B I T
    // Row 1: _ O _ _ R  (only c1=O, c4=R are filled)
    // Row 2: P U L S E
    // Row 3: _ S _ _ E  (only c1=S, c4=E are filled)
    // Row 4: N E X U S
    const ANSWER: (string | null)[][] = [
      ["O", "R", "B", "I", "T"],
      [null, "O", null, null, "R"],
      ["P", "U", "L", "S", "E"],
      [null, "S", null, null, "E"],
      ["N", "E", "X", "U", "S"],
    ];

    // Check each filled cell
    let totalCells = 0;
    let correctCells = 0;
    for (let r = 0; r < 5; r++) {
      for (let c = 0; c < 5; c++) {
        if (ANSWER[r][c] !== null) {
          totalCells++;
          if ((solution[r]?.[c] ?? "").toUpperCase() === ANSWER[r][c]) {
            correctCells++;
          }
        }
      }
    }

    const completed = correctCells === totalCells;
    const xpEarned = completed ? XP_COMPLETE : correctCells >= Math.ceil(totalCells / 2) ? XP_PARTIAL : 0;

    // Insert result
    const { error: insertErr } = await supabase.from("crossword_results").insert({
      user_id: auth.userId,
      puzzle_date: puzzleDate,
      completed,
      xp_earned: xpEarned,
    });

    if (insertErr && insertErr.code !== "23505") throw insertErr;

    // Award XP if any
    if (xpEarned > 0) {
      const { data: stats } = await supabase
        .from("user_stats")
        .select("total_xp, current_streak, longest_streak, last_activity_date")
        .eq("user_id", auth.userId)
        .single();

      const today = new Date().toISOString().slice(0, 10);
      const lastDate = (stats?.last_activity_date as string | null) ?? null;
      const currentStreak = (stats?.current_streak as number) ?? 0;

      let newStreak = currentStreak;
      if (!lastDate) {
        newStreak = 1;
      } else {
        const diff = Math.round((new Date(today).getTime() - new Date(lastDate).getTime()) / (1000 * 60 * 60 * 24));
        if (diff === 1) newStreak = currentStreak + 1;
        else if (diff > 1) newStreak = 1;
      }

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
    }

    return NextResponse.json({
      data: {
        completed,
        correctCells,
        totalCells,
        xpEarned,
        solution: ANSWER,
      },
    });
  } catch (err) {
    console.error("[POST /api/v1/crossword/submit]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to submit crossword" } },
      { status: 500 }
    );
  }
}
