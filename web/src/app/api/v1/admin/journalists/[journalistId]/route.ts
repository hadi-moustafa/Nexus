import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

interface RouteContext {
  params: Promise<{ journalistId: string }>;
}

/**
 * PATCH /api/v1/admin/journalists/[journalistId]
 * Update journalist profile. Admin only.
 *
 * Body (all optional): { name?, bio?, byline_match?, is_verified? }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { journalistId } = await params;
    const body = await request.json();
    const patch: Record<string, unknown> = {};

    if (typeof body.name === "string") patch.name = body.name;
    if (typeof body.bio === "string") patch.bio = body.bio;
    if (typeof body.byline_match === "string") patch.byline_match = body.byline_match;
    if (typeof body.is_verified === "boolean") patch.is_verified = body.is_verified;

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    const { data, error } = await supabase
      .from("journalists")
      .update(patch)
      .eq("id", journalistId)
      .select("id, name, bio, byline_match, is_verified, follower_count")
      .single();

    if (error) throw error;

    return NextResponse.json({ data });
  } catch (err) {
    console.error("[PATCH /api/v1/admin/journalists/[journalistId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update journalist" } },
      { status: 500 }
    );
  }
}
