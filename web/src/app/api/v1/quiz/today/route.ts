import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/quiz/today
 *
 * Returns today's published quiz with its questions (options only, no correct_index).
 * Also returns whether the current user has already completed it.
 *
 * Auth optional — anonymous users get the quiz but cannot submit.
 */
export async function GET(_request: NextRequest) {
  try {
    const supabase = createServiceClient();

    const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD

    // Fetch today's quiz + questions
    const { data: quiz, error } = await supabase
      .from("quizzes")
      .select(`
        id, title, xp_reward, scheduled_for,
        quiz_questions (
          id, question, options, time_limit, position, explanation
        )
      `)
      .eq("scheduled_for", today)
      .eq("is_published", true)
      .order("position", { referencedTable: "quiz_questions", ascending: true })
      .single();

    if (error && error.code !== "PGRST116") throw error;

    if (!quiz) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "No quiz available for today" } },
        { status: 404 }
      );
    }

    // Check if current user already completed it
    let alreadyCompleted = false;
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: result } = await supabase
        .from("quiz_results")
        .select("id, score, xp_earned")
        .eq("quiz_id", quiz.id)
        .eq("user_id", user.id)
        .single();

      if (result) alreadyCompleted = true;
    }

    // Strip correct_index from questions before sending to client
    const questions = (quiz.quiz_questions as unknown as Array<{
      id: string;
      question: string;
      options: string[];
      time_limit: number;
      position: number;
      explanation: string | null;
    }>).map(({ id, question, options, time_limit, position }) => ({
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
        scheduledFor: quiz.scheduled_for,
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
