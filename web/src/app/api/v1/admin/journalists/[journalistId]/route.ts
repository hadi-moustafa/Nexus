import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";
import { logAction } from "@/lib/audit";

interface RouteContext {
  params: Promise<{ journalistId: string }>;
}

const VALID_BADGES = ["rising_star", "popular", "gold", "prolific", "verified", "featured"] as const;

/**
 * PATCH /api/v1/admin/journalists/[journalistId]
 * Update journalist profile and/or manage badges. Admin only.
 *
 * Body (all optional):
 *   { name?, bio?, byline_match?, is_verified?, user_id?,
 *     award_badge?: BadgeType, revoke_badge?: BadgeType }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { journalistId } = await params;
    const body = await request.json();
    const supabase = createServiceClient();

    // Profile field patch
    const patch: Record<string, unknown> = {};
    if (typeof body.name === "string") patch.name = body.name;
    if (typeof body.bio === "string") patch.bio = body.bio;
    if (typeof body.byline_match === "string") patch.byline_match = body.byline_match;
    if (typeof body.is_verified === "boolean") patch.is_verified = body.is_verified;
    if ("user_id" in body) patch.user_id = body.user_id ?? null;

    let profileData: Record<string, unknown> | null = null;
    if (Object.keys(patch).length > 0) {
      const { data, error } = await supabase
        .from("journalists")
        .update(patch)
        .eq("id", journalistId)
        .select("id, name, bio, byline_match, is_verified, follower_count, post_count, user_id")
        .single();
      if (error) throw error;
      profileData = data as Record<string, unknown>;

      // Sync role when linking/unlinking user
      if ("user_id" in body) {
        if (body.user_id) {
          await supabase.from("users").update({ role: "journalist" }).eq("id", body.user_id);
        }
        // If unlinking (null), demote old user_id back to 'user'
        const { data: oldRow } = await supabase
          .from("journalists")
          .select("user_id")
          .eq("id", journalistId)
          .single();
        if (oldRow?.user_id && body.user_id === null) {
          await supabase.from("users").update({ role: "user" }).eq("id", oldRow.user_id);
        }
      }
    }

    // Badge management
    let badgeResult: Record<string, unknown> | null = null;
    if (body.award_badge && VALID_BADGES.includes(body.award_badge)) {
      const { data, error } = await supabase
        .from("journalist_badges")
        .upsert(
          { journalist_id: journalistId, badge_type: body.award_badge, awarded_by: auth.userId },
          { onConflict: "journalist_id,badge_type" }
        )
        .select("id, badge_type, awarded_at")
        .single();
      if (error) throw error;
      badgeResult = { action: "awarded", badge: data };
      void logAction("admin_badge_awarded", auth.userId, { journalistId, badge: body.award_badge }, request);
    } else if (body.revoke_badge && VALID_BADGES.includes(body.revoke_badge)) {
      await supabase
        .from("journalist_badges")
        .delete()
        .eq("journalist_id", journalistId)
        .eq("badge_type", body.revoke_badge);
      badgeResult = { action: "revoked", badgeType: body.revoke_badge };
      void logAction("admin_badge_revoked", auth.userId, { journalistId, badge: body.revoke_badge }, request);
    }

    // Auto-check follower-based badges after any update
    if (profileData || Object.keys(patch).length === 0) {
      const { data: jRow } = await supabase
        .from("journalists")
        .select("follower_count, post_count")
        .eq("id", journalistId)
        .single();

      if (jRow) {
        const fc = (jRow.follower_count as number) ?? 0;
        const pc = (jRow.post_count as number) ?? 0;
        const toAward: string[] = [];
        if (fc >= 10)  toAward.push("rising_star");
        if (fc >= 100) toAward.push("popular");
        if (fc >= 500) toAward.push("gold");
        if (pc >= 50)  toAward.push("prolific");

        if (toAward.length > 0) {
          await supabase.from("journalist_badges").upsert(
            toAward.map((bt) => ({ journalist_id: journalistId, badge_type: bt })),
            { onConflict: "journalist_id,badge_type", ignoreDuplicates: true }
          );
        }
      }
    }

    return NextResponse.json({ data: profileData, badge: badgeResult });
  } catch (err) {
    console.error("[PATCH /api/v1/admin/journalists/[journalistId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update journalist" } },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/v1/admin/journalists/[journalistId]
 * Delete a journalist profile. Admin only.
 */
export async function DELETE(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { journalistId } = await params;
    const supabase = createServiceClient();

    // Demote linked user before deleting
    const { data: jRow } = await supabase
      .from("journalists")
      .select("user_id")
      .eq("id", journalistId)
      .single();
    if (jRow?.user_id) {
      await supabase.from("users").update({ role: "user" }).eq("id", jRow.user_id);
    }

    const { error } = await supabase.from("journalists").delete().eq("id", journalistId);
    if (error) throw error;

    return new NextResponse(null, { status: 204 });
  } catch (err) {
    console.error("[DELETE /api/v1/admin/journalists/[journalistId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to delete journalist" } },
      { status: 500 }
    );
  }
}
