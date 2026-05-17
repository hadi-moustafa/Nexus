import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/journalists
 * Returns all journalist profiles with badges and linked user. Admin only.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("journalists")
      .select(`
        id, name, bio, avatar_url, byline_match, is_verified,
        follower_count, post_count, user_id, created_at,
        journalist_badges ( id, badge_type, awarded_at )
      `)
      .order("created_at", { ascending: false });

    if (error) throw error;

    // Resolve linked user emails
    const rows = data ?? [];
    const userIds = rows.map((r) => r.user_id as string | null).filter(Boolean) as string[];

    let userEmailMap: Record<string, string> = {};
    if (userIds.length > 0) {
      const { data: users } = await supabase
        .from("users")
        .select("id, email, display_name")
        .in("id", userIds);
      for (const u of users ?? []) {
        userEmailMap[u.id as string] = (u.email as string) ?? "";
      }
    }

    const result = rows.map((j) => ({
      ...j,
      linkedUserEmail: j.user_id ? (userEmailMap[j.user_id as string] ?? null) : null,
    }));

    return NextResponse.json({ data: result });
  } catch (err) {
    console.error("[GET /api/v1/admin/journalists]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch journalists" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/admin/journalists
 * Creates a journalist profile. Admin only.
 * Body: { name, byline_match?, bio?, user_id? }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { name, byline_match, bio, user_id } = await request.json();

    if (!name || typeof name !== "string") {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "name is required" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("journalists")
      .insert({
        name,
        byline_match: byline_match ?? null,
        bio: bio ?? null,
        user_id: user_id ?? null,
      })
      .select("id, name, bio, byline_match, is_verified, follower_count, post_count, user_id, created_at")
      .single();

    if (error) throw error;

    // If user_id provided, promote that user to journalist role
    if (user_id) {
      await supabase.from("users").update({ role: "journalist" }).eq("id", user_id);
    }

    return NextResponse.json({ data: { ...data, journalist_badges: [], linkedUserEmail: null } }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/admin/journalists]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to create journalist" } },
      { status: 500 }
    );
  }
}
