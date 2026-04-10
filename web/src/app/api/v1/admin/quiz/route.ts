import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/quiz
 * Returns recent quizzes (last 14 days). Admin only.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { data, error } = await supabase
      .from("quizzes")
      .select(`
        id, title, scheduled_for, is_published, xp_reward, created_at,
        quiz_questions ( id )
      `)
      .order("scheduled_for", { ascending: false })
      .limit(14);

    if (error) throw error;

    const quizzes = (data ?? []).map((q) => ({
      ...q,
      questionCount: Array.isArray(q.quiz_questions) ? q.quiz_questions.length : 0,
      quiz_questions: undefined,
    }));

    return NextResponse.json({ data: quizzes });
  } catch (err) {
    console.error("[GET /api/v1/admin/quiz]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch quizzes" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/admin/quiz
 * Creates a new quiz with questions. Admin only.
 *
 * Body:
 * {
 *   title: string,
 *   scheduled_for: string,  // YYYY-MM-DD
 *   xp_reward?: number,
 *   questions: Array<{
 *     question: string,
 *     options: string[],
 *     correct_index: number,
 *     explanation?: string,
 *     time_limit?: number
 *   }>
 * }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const body = await request.json();
    const { title, scheduled_for, xp_reward = 100, questions = [] } = body;

    if (!scheduled_for || !Array.isArray(questions) || questions.length === 0) {
      return NextResponse.json(
        {
          error: {
            code: "VALIDATION_ERROR",
            message: "scheduled_for and at least one question are required",
          },
        },
        { status: 400 }
      );
    }

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    // Create quiz
    const { data: quiz, error: qErr } = await supabase
      .from("quizzes")
      .insert({ title: title ?? "Daily News Quiz", scheduled_for, xp_reward, is_published: false })
      .select("id")
      .single();

    if (qErr) throw qErr;

    // Insert questions
    const rows = questions.map((q: {
      question: string;
      options: string[];
      correct_index: number;
      explanation?: string;
      time_limit?: number;
    }, i: number) => ({
      quiz_id: quiz.id,
      question: q.question,
      options: q.options,
      correct_index: q.correct_index,
      explanation: q.explanation ?? null,
      time_limit: q.time_limit ?? 20,
      position: i,
    }));

    const { error: insertErr } = await supabase.from("quiz_questions").insert(rows);
    if (insertErr) throw insertErr;

    return NextResponse.json({ data: { id: quiz.id } }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/admin/quiz]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to create quiz" } },
      { status: 500 }
    );
  }
}
