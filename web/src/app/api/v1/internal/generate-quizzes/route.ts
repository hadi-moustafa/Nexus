import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { GoogleGenerativeAI } from "@google/generative-ai";

/**
 * POST /api/v1/internal/generate-quizzes
 *
 * Bulk-generates daily quizzes using Gemini AI based on recent articles.
 * Skips dates that already have a quiz. Auto-publishes all created quizzes.
 *
 * Body (all optional):
 *   { days?: number, startDate?: string }  // defaults: 30 days from today
 *
 * Protected by CRON_SECRET header (same as other internal endpoints).
 */
export async function POST(request: NextRequest) {
  const secret = request.headers.get("x-cron-secret");
  if (process.env.CRON_SECRET && secret !== process.env.CRON_SECRET) {
    return NextResponse.json({ error: { code: "FORBIDDEN" } }, { status: 403 });
  }

  try {
    const body = await request.json().catch(() => ({})) as { days?: number; startDate?: string };
    const days = Math.min(body.days ?? 30, 60);
    const startDate = body.startDate ?? new Date().toISOString().slice(0, 10);

    const supabase = createServiceClient();

    // Find which dates in the range already have a quiz
    const dates = Array.from({ length: days }, (_, i) => {
      const d = new Date(startDate);
      d.setDate(d.getDate() + i);
      return d.toISOString().slice(0, 10);
    });

    const { data: existing } = await supabase
      .from("quizzes")
      .select("scheduled_for")
      .in("scheduled_for", dates);

    const existingDates = new Set((existing ?? []).map((r) => r.scheduled_for as string));
    const missingDates = dates.filter((d) => !existingDates.has(d));

    if (missingDates.length === 0) {
      return NextResponse.json({ data: { created: 0, message: "All dates already have quizzes." } });
    }

    // Fetch recent articles to draw questions from (last 60 days, up to 100)
    const since = new Date();
    since.setDate(since.getDate() - 60);
    const { data: articleRows } = await supabase
      .from("articles")
      .select("id, title, description, category, url")
      .gte("published_at", since.toISOString())
      .not("description", "is", null)
      .order("published_at", { ascending: false })
      .limit(100);

    const articles = (articleRows ?? []).filter(
      (a) => a.description && (a.description as string).trim().length > 30
    );

    if (articles.length < 5) {
      return NextResponse.json(
        { error: { code: "NOT_ENOUGH_ARTICLES", message: "Not enough articles to generate quiz questions from." } },
        { status: 422 }
      );
    }

    const geminiKey = process.env.GEMINI_API_KEY;
    if (!geminiKey) {
      return NextResponse.json(
        { error: { code: "CONFIG_ERROR", message: "GEMINI_API_KEY not set." } },
        { status: 500 }
      );
    }

    const model = new GoogleGenerativeAI(geminiKey).getGenerativeModel({
      model: "gemini-2.0-flash",
    });

    let created = 0;
    const errors: string[] = [];

    for (const dateStr of missingDates) {
      try {
        // Pick 8 random articles as source material for variety
        const pool = [...articles].sort(() => Math.random() - 0.5).slice(0, 8);
        const articleList = pool
          .map(
            (a, i) =>
              `${i + 1}. [${(a.category as string).toUpperCase()}] ${a.title as string}\n   ${(a.description as string).slice(0, 200)}`
          )
          .join("\n\n");

        const prompt = `You are a news trivia quiz master. Based on the following news articles, create exactly 5 multiple-choice quiz questions.

NEWS ARTICLES:
${articleList}

Rules:
- Each question must be factual and answerable from the article descriptions above.
- Each question must have exactly 4 options.
- Exactly one option is correct; the others are plausible but wrong.
- Do NOT reference the article number or source in the question.
- Questions should test knowledge of facts, not opinion.
- Mix easy and medium difficulty.
- Vary question styles: "What/Who/When/Where/Which" etc.

Respond with ONLY a valid JSON array (no markdown, no extra text):
[
  {
    "question": "...",
    "options": ["...", "...", "...", "..."],
    "correct_index": 0,
    "explanation": "Brief explanation of the correct answer."
  }
]`;

        const result = await model.generateContent(prompt);
        const text = result.response.text().trim();
        const cleaned = text.replace(/^```(?:json)?\n?/, "").replace(/\n?```$/, "").trim();

        let questions: Array<{
          question: string;
          options: string[];
          correct_index: number;
          explanation: string;
        }>;

        try {
          questions = JSON.parse(cleaned);
        } catch {
          errors.push(`${dateStr}: JSON parse failed`);
          continue;
        }

        if (!Array.isArray(questions) || questions.length === 0) {
          errors.push(`${dateStr}: No questions returned`);
          continue;
        }

        // Validate structure
        const valid = questions.filter(
          (q) =>
            typeof q.question === "string" &&
            Array.isArray(q.options) &&
            q.options.length === 4 &&
            typeof q.correct_index === "number" &&
            q.correct_index >= 0 &&
            q.correct_index <= 3
        );

        if (valid.length === 0) {
          errors.push(`${dateStr}: All questions failed validation`);
          continue;
        }

        // Insert quiz
        const { data: quiz, error: quizErr } = await supabase
          .from("quizzes")
          .insert({
            title: "Daily News Quiz",
            scheduled_for: dateStr,
            xp_reward: 100,
            is_published: true,
          })
          .select("id")
          .single();

        if (quizErr) {
          errors.push(`${dateStr}: DB insert failed — ${quizErr.message}`);
          continue;
        }

        const rows = valid.map((q, i) => ({
          quiz_id: quiz.id,
          question: q.question,
          options: q.options,
          correct_index: q.correct_index,
          explanation: q.explanation ?? null,
          time_limit: 20,
          position: i,
        }));

        const { error: qErr } = await supabase.from("quiz_questions").insert(rows);
        if (qErr) {
          errors.push(`${dateStr}: Questions insert failed — ${qErr.message}`);
          // Roll back the quiz row
          await supabase.from("quizzes").delete().eq("id", quiz.id);
          continue;
        }

        created++;
      } catch (err) {
        errors.push(`${dateStr}: ${String(err)}`);
      }

      // Small delay between Gemini calls to avoid rate limiting
      await new Promise((r) => setTimeout(r, 800));
    }

    return NextResponse.json({
      data: {
        created,
        skipped: existingDates.size,
        errors: errors.length > 0 ? errors : undefined,
      },
    });
  } catch (err) {
    console.error("[POST /api/v1/internal/generate-quizzes]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to generate quizzes" } },
      { status: 500 }
    );
  }
}
