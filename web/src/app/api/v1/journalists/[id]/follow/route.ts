import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

interface RouteContext {
  params: Promise<{ id: string }>;
}

/**
 * POST /api/v1/journalists/[id]/follow
 * Follow a journalist. Requires auth.
 */
export async function POST(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { id: journalistId } = await params;
    const supabase = createServiceClient();

    const { error } = await supabase
      .from("journalist_follows")
      .insert({ journalist_id: journalistId, user_id: auth.userId });

    if (error) {
      if (error.code === "23505") {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "Already following" } },
          { status: 409 }
        );
      }
      throw error;
    }

    // Increment follower_count (best-effort: re-count from follows table)
    const { count } = await supabase
      .from("journalist_follows")
      .select("*", { count: "exact", head: true })
      .eq("journalist_id", journalistId);
    if (count !== null) {
      await supabase
        .from("journalists")
        .update({ follower_count: count })
        .eq("id", journalistId);
    }

    return NextResponse.json({ data: { following: true } }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/journalists/[id]/follow]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to follow journalist" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/journalists/[id]/follow
 * Unfollow a journalist. Requires auth.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { id: journalistId } = await params;
    const supabase = createServiceClient();

    const { error } = await supabase
      .from("journalist_follows")
      .delete()
      .eq("journalist_id", journalistId)
      .eq("user_id", auth.userId);

    if (error) throw error;

    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/journalists/[id]/follow]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to unfollow journalist" } },
      { status: 500 }
    );
  }
}
