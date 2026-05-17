import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

/**
 * GET /api/v1/journalist/profile
 *
 * Returns the authenticated journalist's profile + their recent posts + badges.
 * Used by the mobile Studio screen to render the journalist dashboard.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const supabase = createServiceClient();

    const { data: journalistRow, error } = await supabase
      .from("journalists")
      .select(`
        id, name, bio, avatar_url, is_verified, follower_count, post_count,
        journalist_badges ( id, badge_type, awarded_at )
      `)
      .eq("user_id", auth.userId)
      .single();

    if (error?.code === "PGRST116" || !journalistRow) {
      return NextResponse.json(
        { error: { code: "NOT_FOUND", message: "No journalist profile linked to your account" } },
        { status: 404 }
      );
    }
    if (error) throw error;

    const { data: posts } = await supabase
      .from("journalist_posts")
      .select("id, title, image_url, category, comment_count, reaction_count, view_count, created_at")
      .eq("journalist_id", journalistRow.id)
      .order("created_at", { ascending: false })
      .limit(20);

    const rawBadges = journalistRow.journalist_badges as unknown as Array<Record<string, unknown>> ?? [];

    return NextResponse.json({
      data: {
        id: journalistRow.id as string,
        name: journalistRow.name as string,
        bio: (journalistRow.bio as string | null) ?? null,
        avatarUrl: (journalistRow.avatar_url as string | null) ?? null,
        isVerified: journalistRow.is_verified as boolean,
        followerCount: journalistRow.follower_count as number,
        postCount: journalistRow.post_count as number,
        badges: rawBadges.map((b) => ({
          id: b.id as string,
          badgeType: b.badge_type as string,
          awardedAt: b.awarded_at as string,
        })),
        recentPosts: (posts ?? []).map((p) => ({
          id: p.id as string,
          title: p.title as string,
          imageUrl: (p.image_url as string | null) ?? null,
          category: (p.category as string) ?? "general",
          commentCount: (p.comment_count as number) ?? 0,
          reactionCount: (p.reaction_count as number) ?? 0,
          viewCount: (p.view_count as number) ?? 0,
          createdAt: p.created_at as string,
        })),
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/journalist/profile]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch journalist profile" } },
      { status: 500 }
    );
  }
}
