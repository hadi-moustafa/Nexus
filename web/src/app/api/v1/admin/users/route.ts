import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/users
 * Returns paginated user list. Admin only.
 *
 * Query params:
 *   limit   number  (default 50, max 100)
 *   cursor  string  (user id for keyset pagination)
 *   q       string  (search by email or display_name)
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "50"), 100);
    const cursor = searchParams.get("cursor") ?? undefined;
    const q = searchParams.get("q") ?? undefined;

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    let query = supabase
      .from("users")
      .select("id, email, display_name, role, created_at")
      .order("created_at", { ascending: false })
      .limit(limit + 1);

    if (q) {
      query = query.or(`email.ilike.%${q}%,display_name.ilike.%${q}%`);
    }
    if (cursor) {
      query = query.lt("created_at", cursor);
    }

    const { data, error } = await query;
    if (error) throw error;

    const rows = data ?? [];
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    return NextResponse.json({
      data: page,
      meta: { nextCursor: hasMore ? page[page.length - 1].created_at : null },
    });
  } catch (err) {
    console.error("[GET /api/v1/admin/users]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch users" } },
      { status: 500 }
    );
  }
}
