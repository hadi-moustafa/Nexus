import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { rateLimit, rateLimitResponse } from "@/lib/rate-limit";

const XP_PER_CORRECT = 10;
const PERFECT_BONUS = 20;
const STREAK_BONUS = 5; // per streak day, capped at 50

/**
 * POST /api/v1/quiz/submit
 *
 * Submits quiz answers, scores them server-side, awards XP, updates streak.
 * Streak logic:
 *   - Same-day submission after already submitting: rejected (409)
 *   - Consecutive day: streak + 1
 *   - Gap > 1 day: streak resets to 1
 *
 * Body: { quizId: string, answers: number[] }
 *   answers = array of selected option indices (0-based), one per question,
 *             in the same order as quiz_questions.position.
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  // 5 submissions per user per hour (DB unique constraint also enforces one per quiz)
  const rl = rateLimit(`quiz:submit:${auth.userId}`, 5, 60 * 60 * 1000);
  if (!rl.ok) return rateLimitResponse(rl.resetAt) as NextResponse;

  try {
    const { quizId, answers } = await request.json();

    if (!quizId || !Array.isArray(answers)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "quizId and answers[] are required" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    // Prevent double-submission
    const { data: existing } = await supabase
      .from("quiz_results")
      .select("id, score, xp_earned")
      .eq("quiz_id", quizId)
      .eq("user_id", auth.userId)
      .single();

    if (existing) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Quiz already submitted" } },
        { status: 409 }
      );
    }

    // Fetch correct answers (server-side only)
    const { data: questions, error: qErr } = await supabase
      .from("quiz_questions")
      .select("id, correct_index, position")
      .eq("quiz_id", quizId)
      .order("position", { ascending: true });

    if (qErr) throw qErr;
    if (!questions || questions.length === 0) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "Quiz questions not found" } },
        { status: 404 }
      );
    }

    // Fetch quiz XP reward
    const { data: quiz } = await supabase
      .from("quizzes")
      .select("xp_reward")
      .eq("id", quizId)
      .single();

    // Score answers
    const correct = questions.map((q, i) => answers[i] === q.correct_index);
    const score = correct.filter(Boolean).length;
    const isPerfect = score === questions.length;

    // Fetch current stats for streak calculation
    const { data: stats } = await supabase
      .from("user_stats")
      .select("current_streak, longest_streak, total_xp, quizzes_completed, perfect_scores, last_activity_date")
      .eq("user_id", auth.userId)
      .single();

    // Date-based streak logic
    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
    const lastDate = stats?.last_activity_date as string | null ?? null;
    let currentStreak = (stats?.current_streak as number) ?? 0;

    let newStreak: number;
    if (!lastDate) {
      newStreak = 1;
    } else {
      const last = new Date(lastDate);
      const now = new Date(today);
      const diffDays = Math.round((now.getTime() - last.getTime()) / (1000 * 60 * 60 * 24));
      if (diffDays === 1) {
        newStreak = currentStreak + 1; // consecutive day
      } else if (diffDays === 0) {
        // Same day — still count this quiz attempt but don't increment streak again
        newStreak = currentStreak;
      } else {
        newStreak = 1; // streak broken
      }
    }

    const streakBonus = Math.min(newStreak * STREAK_BONUS, 50);

    const baseXp = score * XP_PER_CORRECT + (isPerfect ? PERFECT_BONUS : 0) + streakBonus;
    const xpEarned = quiz?.xp_reward
      ? Math.round((baseXp / (questions.length * XP_PER_CORRECT + PERFECT_BONUS + 50)) * quiz.xp_reward)
      : baseXp;

    // Insert quiz result
    const { error: insertErr } = await supabase.from("quiz_results").insert({
      quiz_id: quizId,
      user_id: auth.userId,
      score,
      xp_earned: xpEarned,
      answers,
      streak_day: newStreak,
    });

    if (insertErr) {
      if (insertErr.code === "23505") {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "Quiz already submitted" } },
          { status: 409 }
        );
      }
      throw insertErr;
    }

    // Update user_stats (XP, streak, counts)
    const { error: statsErr } = await supabase.from("user_stats").upsert(
      {
        user_id: auth.userId,
        total_xp: ((stats?.total_xp as number) ?? 0) + xpEarned,
        current_streak: newStreak,
        longest_streak: Math.max((stats?.longest_streak as number) ?? 0, newStreak),
        quizzes_completed: ((stats?.quizzes_completed as number) ?? 0) + 1,
        perfect_scores: ((stats?.perfect_scores as number) ?? 0) + (isPerfect ? 1 : 0),
        last_activity_date: today,
      },
      { onConflict: "user_id" }
    );

    if (statsErr) throw statsErr;

    return NextResponse.json({
      data: {
        score,
        total: questions.length,
        isPerfect,
        xpEarned,
        newStreak,
        // Which answers were correct (for results screen)
        correctAnswers: questions.map((q) => q.correct_index),
      },
    });
  } catch (err) {
    console.error("[POST /api/v1/quiz/submit]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to submit quiz" } },
      { status: 500 }
    );
  }
}
