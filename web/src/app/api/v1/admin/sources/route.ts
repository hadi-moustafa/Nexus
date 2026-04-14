import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/sources
 * Returns all news sources. Admin only.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("news_sources")
      .select("id, name, base_url, is_active, updated_at")
      .order("name", { ascending: true });

    if (error) throw error;

    return NextResponse.json({ data: data ?? [] });
  } catch (err) {
    console.error("[GET /api/v1/admin/sources]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch sources" } },
      { status: 500 }
    );
  }
}

/**
 * POST /api/v1/admin/sources
 * Creates a new news source. Admin only.
 *
 * Body: { name: string, base_url: string }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { name, base_url } = await request.json();

    if (!name || !base_url) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "name and base_url are required" } },
        { status: 400 }
      );
    }

    const supabase = createServiceClient();

    const { data, error } = await supabase
      .from("news_sources")
      .insert({ name, base_url, is_active: true })
      .select("id, name, base_url, is_active, updated_at")
      .single();

    if (error) throw error;

    return NextResponse.json({ data }, { status: 201 });
  } catch (err) {
    console.error("[POST /api/v1/admin/sources]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to create source" } },
      { status: 500 }
    );
  }
}
