import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

interface RouteContext {
  params: Promise<{ sourceId: string }>;
}

/**
 * PATCH /api/v1/admin/sources/[sourceId]
 * Toggle is_active or update fields. Admin only.
 *
 * Body (all optional): { name?: string, base_url?: string, is_active?: boolean }
 */
export async function PATCH(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { sourceId } = await params;
    const body = await request.json();
    const patch: Record<string, unknown> = { updated_at: new Date().toISOString() };

    if (typeof body.name === "string") patch.name = body.name;
    if (typeof body.base_url === "string") patch.base_url = body.base_url;
    if (typeof body.is_active === "boolean") patch.is_active = body.is_active;

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("news_sources")
      .update(patch)
      .eq("id", sourceId)
      .select("id, name, base_url, is_active, updated_at")
      .single();

    if (error) throw error;

    return NextResponse.json({ data });
  } catch (err) {
    console.error("[PATCH /api/v1/admin/sources/[sourceId]]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update source" } },
      { status: 500 }
    );
  }
}
