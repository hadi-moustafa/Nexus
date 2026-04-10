import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

const STREAK_BONUS = 5; // per streak day, capped at 50

/**
 * POST /api/v1/quiz/general/submit
 *
 * Scores a general knowledge quiz session, awards XP, updates streak.
 * No daily limit — users can play multiple rounds per day.
 *
 * Body: { questionIds: string[], answers: number[], difficulty: string }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const body = await request.json();
    const { questionIds, answers, difficulty } = body as {
      questionIds?: string[];
      answers?: number[];
      difficulty?: string;
    };

    if (
      !Array.isArray(questionIds) ||
      !Array.isArray(answers) ||
      questionIds.length !== answers.length ||
      !difficulty ||
      !["easy", "medium", "hard"].includes(difficulty)
    ) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "questionIds[], answers[], and difficulty are required" } },
        { status: 400 }
      );
    }

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    // Fetch correct answers server-side
    const { data: questions, error: qErr } = await supabase
      .from("general_questions")
      .select("id, correct_index, xp_value")
      .in("id", questionIds);

    if (qErr) throw qErr;
    if (!questions || questions.length === 0) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "Questions not found" } },
        { status: 404 }
      );
    }

    // Build a lookup map for correct answers
    const answerMap = new Map(questions.map((q) => [q.id as string, { correctIndex: q.correct_index as number, xpValue: q.xp_value as number }]));

    // Score in the order questions were sent
    let totalXp = 0;
    const results = questionIds.map((qId, i) => {
      const meta = answerMap.get(qId);
      if (!meta) return { questionId: qId, correct: false, correctIndex: -1, xpAwarded: 0 };
      const isCorrect = answers[i] === meta.correctIndex;
      const xpAwarded = isCorrect ? meta.xpValue : 0;
      totalXp += xpAwarded;
      return { questionId: qId, correct: isCorrect, correctIndex: meta.correctIndex, xpAwarded };
    });

    const score = results.filter((r) => r.correct).length;

    // Streak logic
    const today = new Date().toISOString().slice(0, 10);
    const { data: stats } = await supabase
      .from("user_stats")
      .select("current_streak, longest_streak, total_xp, quizzes_completed, perfect_scores, last_activity_date")
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
      if (diffDays === 1) {
        newStreak = currentStreak + 1;
      } else if (diffDays === 0) {
        newStreak = currentStreak; // already active today, don't increment
      } else {
        newStreak = 1;
      }
    }

    const streakBonus = Math.min(newStreak * STREAK_BONUS, 50);
    const xpEarned = totalXp + streakBonus;

    // Insert result row
    const { error: insertErr } = await supabase.from("general_quiz_results").insert({
      user_id: auth.userId,
      difficulty,
      score,
      total: questionIds.length,
      xp_earned: xpEarned,
      answers,
    });

    if (insertErr) throw insertErr;

    // Update user_stats
    const { error: statsErr } = await supabase.from("user_stats").upsert(
      {
        user_id: auth.userId,
        total_xp: ((stats?.total_xp as number) ?? 0) + xpEarned,
        current_streak: newStreak,
        longest_streak: Math.max((stats?.longest_streak as number) ?? 0, newStreak),
        quizzes_completed: ((stats?.quizzes_completed as number) ?? 0) + 1,
        perfect_scores: ((stats?.perfect_scores as number) ?? 0) + (score === questionIds.length ? 1 : 0),
        last_activity_date: today,
      },
      { onConflict: "user_id" }
    );

    if (statsErr) throw statsErr;

    return NextResponse.json({
      data: {
        score,
        total: questionIds.length,
        xpEarned,
        streakBonus,
        newStreak,
        results,
      },
    });
  } catch (err) {
    console.error("[POST /api/v1/quiz/general/submit]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to submit quiz" } },
      { status: 500 }
    );
  }
}
