import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

interface RouteContext {
  params: Promise<{ quizId: string }>;
}

/**
 * PATCH /api/v1/admin/quiz/[quizId]
 * Toggle is_published or update fields. Admin only.
 *
 * Body (all optional): { is_published?, title?, xp_reward?, scheduled_for? }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { quizId } = await params;
    const body = await request.json();
    const patch: Record<string, unknown> = {};

    if (typeof body.is_published === "boolean") patch.is_published = body.is_published;
    if (typeof body.title === "string") patch.title = body.title;
    if (typeof body.xp_reward === "number") patch.xp_reward = body.xp_reward;
    if (typeof body.scheduled_for === "string") patch.scheduled_for = body.scheduled_for;

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("quizzes")
      .update(patch)
      .eq("id", quizId)
      .select("id, title, scheduled_for, is_published, xp_reward")
      .single();

    if (error) throw error;

    return NextResponse.json({ data });
  } catch (err) {
    console.error("[PATCH /api/v1/admin/quiz/[quizId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update quiz" } },
      { status: 500 }
    );
  }
}
