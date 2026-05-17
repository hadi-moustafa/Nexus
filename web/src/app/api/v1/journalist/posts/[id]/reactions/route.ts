import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { rateLimit, rateLimitResponse } from "@/lib/rate-limit";

interface RouteContext {
  params: Promise<{ id: string }>;
}

const VALID_TYPES = ["like", "love", "wow", "sad", "angry"] as const;

/**
 * GET /api/v1/journalist/posts/[id]/reactions
 * Returns reaction counts grouped by type, and the current user's reaction if authenticated.
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  try {
    const { id: postId } = await params;
    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("post_reactions")
      .select("type, user_id")
      .eq("post_id", postId);

    if (error) throw error;

    const rows = data ?? [];
    const counts: Record<string, number> = { like: 0, love: 0, wow: 0, sad: 0, angry: 0 };
    for (const r of rows) counts[r.type as string] = (counts[r.type as string] ?? 0) + 1;

    const { data: { user } } = await supabase.auth.getUser();
    const myReaction = user
      ? (rows.find((r) => r.user_id === user.id)?.type ?? null)
      : null;

    return NextResponse.json({ data: { counts, myReaction } });
  } catch (err) {
    console.error("[GET /api/v1/journalist/posts/[id]/reactions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch reactions" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/journalist/posts/[id]/reactions
 * Toggle a reaction on a post. Sending the same type removes it.
 * Body: { type: "like"|"love"|"wow"|"sad"|"angry" }
 */
export async function POST(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  const rl = rateLimit(`post_reaction:${auth.userId}`, 30, 60 * 1000);
  if (!rl.ok) return rateLimitResponse(rl.resetAt) as NextResponse;

  try {
    const { id: postId } = await params;
    const { type } = await request.json();

    if (!VALID_TYPES.includes(type)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "Invalid reaction type" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    const { data: existing } = await supabase
      .from("post_reactions")
      .select("id, type")
      .eq("post_id", postId)
      .eq("user_id", auth.userId)
      .maybeSingle();

    if (existing) {
      if (existing.type === type) {
        // Same type — remove (toggle off)
        await supabase.from("post_reactions").delete().eq("id", existing.id);
        return NextResponse.json({ data: { action: "removed", type } });
      }
      // Different type — update
      await supabase.from("post_reactions").update({ type }).eq("id", existing.id);
      return NextResponse.json({ data: { action: "updated", type } });
    }

    await supabase.from("post_reactions").insert({ post_id: postId, user_id: auth.userId, type });
    return NextResponse.json({ data: { action: "added", type } }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/journalist/posts/[id]/reactions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update reaction" } },
      { status: 500 }
    );
  }
}
