import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

interface RouteContext {
  params: Promise<{ id: string }>;
}

const VALID_TYPES = ["like", "love", "wow", "sad", "angry"] as const;
type ReactionType = (typeof VALID_TYPES)[number];

/**
 * GET /api/v1/articles/[id]/reactions
 * Returns aggregated reaction counts + the current user's reaction (if any).
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  try {
    const { id: articleId } = await params;
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    // Aggregate counts
    const { data: rows, error } = await supabase
      .from("reactions")
      .select("type")
      .eq("article_id", articleId);

    if (error) throw error;

    const counts: Record<string, number> = {};
    for (const row of rows ?? []) {
      const t = row.type as string;
      counts[t] = (counts[t] ?? 0) + 1;
    }

    // Current user's reaction (best-effort, no error if not authed)
    let myReaction: string | null = null;
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      const { data: mine } = await supabase
        .from("reactions")
        .select("type")
        .eq("article_id", articleId)
        .eq("user_id", user.id)
        .single();
      myReaction = mine?.type ?? null;
    }

    return NextResponse.json({ data: { counts, myReaction } });
  } catch (err) {
    console.error("[GET /api/v1/articles/[id]/reactions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch reactions" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/articles/[id]/reactions
 * Upserts a reaction (one per user per article). Requires auth.
 *
 * Body: { type: "like" | "love" | "wow" | "sad" | "angry" }
 */
export async function POST(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { id: articleId } = await params;
    const { type } = await request.json();

    if (!VALID_TYPES.includes(type as ReactionType)) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: `type must be one of: ${VALID_TYPES.join(", ")}` } },
        { status: 400 }
      );
    }

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { error } = await supabase
      .from("reactions")
      .upsert(
        { article_id: articleId, user_id: auth.userId, type },
        { onConflict: "article_id,user_id" }
      );

    if (error) throw error;

    return NextResponse.json({ data: { articleId, type } }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/articles/[id]/reactions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to add reaction" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/articles/[id]/reactions
 * Removes the current user's reaction. Requires auth.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { id: articleId } = await params;
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { error } = await supabase
      .from("reactions")
      .delete()
      .eq("article_id", articleId)
      .eq("user_id", auth.userId);

    if (error) throw error;

    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/articles/[id]/reactions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to remove reaction" } },
      { status: 500 }
    );
  }
}
