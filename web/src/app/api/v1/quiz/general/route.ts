import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/quiz/general?difficulty=easy|medium|hard
 *
 * Returns 5 random general knowledge questions for the given difficulty tier.
 * correct_index is NOT sent to the client.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const difficulty = searchParams.get("difficulty") ?? "easy";

  if (!["easy", "medium", "hard"].includes(difficulty)) {
    return NextResponse.json(
      { error: { code: "VALIDATION_ERROR", message: "difficulty must be easy, medium, or hard" } },
      { status: 400 }
    );
  }

  try {
    const supabase = createServiceClient();

    // Fetch a random sample of 5 questions for the difficulty
    const { data: questions, error } = await supabase
      .from("general_questions")
      .select("id, question, options, explanation, difficulty, category, xp_value")
      .eq("difficulty", difficulty)
      .limit(50); // fetch more, shuffle server-side

    if (error) throw error;

    if (!questions || questions.length === 0) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "No questions found for this difficulty" } },
        { status: 404 }
      );
    }

    // Server-side shuffle + take 5
    const shuffled = [...questions].sort(() => Math.random() - 0.5).slice(0, 5);

    return NextResponse.json({
      data: {
        difficulty,
        questions: shuffled.map((q) => ({
          id: q.id,
          question: q.question,
          options: q.options,
          category: q.category,
          xpValue: q.xp_value,
          // correct_index intentionally omitted
        })),
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/quiz/general]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch questions" } },
      { status: 500 }
    );
  }
}
