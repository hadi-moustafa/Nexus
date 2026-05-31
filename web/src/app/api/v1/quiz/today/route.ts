import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/quiz/today
 *
 * Picks today's quiz from the pool by rotating through all published quizzes
 * using (days since epoch % pool size). The same quiz repeats on the same
 * calendar day worldwide.
 *
 * Auth optional — anonymous users get the quiz but cannot submit.
 * alreadyCompleted is true if the authenticated user already submitted
 * a quiz today (any quiz).
 */
export async function GET(_request: NextRequest) {
  try {
    const supabase = createServiceClient();

    // Fetch all published quizzes ordered by creation date (stable pool order)
    const { data: pool, error: poolErr } = await supabase
      .from("quizzes")
      .select(`
        id, title, xp_reward, scheduled_for,
        quiz_questions (
          id, question, options, time_limit, position, explanation
        )
      `)
      .eq("is_published", true)
      .order("quiz_date", { ascending: true });

    if (poolErr) throw poolErr;

    if (!pool || pool.length === 0) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "No quizzes available" } },
        { status: 404 }
      );
    }

    // Pick today's quiz: (days since Unix epoch) % pool size
    const today = new Date().toISOString().slice(0, 10);
    const daysSinceEpoch = Math.floor(Date.now() / (1000 * 60 * 60 * 24));
    const quiz = pool[daysSinceEpoch % pool.length];

    // Check if current user already completed a quiz today
    let alreadyCompleted = false;
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: result } = await supabase
        .from("quiz_results")
        .select("id")
        .eq("user_id", user.id)
        .gte("completed_at", `${today}T00:00:00.000Z`)
        .lt("completed_at", `${today}T23:59:59.999Z`)
        .maybeSingle();

      if (result) alreadyCompleted = true;
    }

    // Strip correct_index before sending to client
    const questions = (quiz.quiz_questions as unknown as Array<{
      id: string;
      question: string;
      options: string[];
      time_limit: number;
      position: number;
      explanation: string | null;
    }>)
      .sort((a, b) => a.position - b.position)
      .map(({ id, question, options, time_limit, position }) => ({
        id,
        question,
        options,
        timeLimit: time_limit,
        position,
      }));

    return NextResponse.json({
      data: {
        id: quiz.id,
        title: quiz.title ?? "Daily News Quiz",
        xpReward: quiz.xp_reward,
        scheduledFor: today,
        questions,
        alreadyCompleted,
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/quiz/today]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch quiz" } },
      { status: 500 }
    );
  }
}
