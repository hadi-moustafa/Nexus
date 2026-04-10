import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/journalists
 * Returns all journalist profiles. Admin only.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { data, error } = await supabase
      .from("journalists")
      .select("id, name, bio, avatar_url, byline_match, is_verified, follower_count, created_at")
      .order("created_at", { ascending: false });

    if (error) throw error;

    return NextResponse.json({ data: data ?? [] });
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
 *
 * Body: { name: string, byline_match?: string, bio?: string }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { name, byline_match, bio } = await request.json();

    if (!name || typeof name !== "string") {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "name is required" } },
        { status: 400 }
      );
    }

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { data, error } = await supabase
      .from("journalists")
      .insert({ name, byline_match: byline_match ?? null, bio: bio ?? null })
      .select("id, name, bio, byline_match, is_verified, follower_count, created_at")
      .single();

    if (error) throw error;

    return NextResponse.json({ data }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/admin/journalists]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to create journalist" } },
      { status: 500 }
    );
  }
}
