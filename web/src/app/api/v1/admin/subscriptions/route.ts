import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAdminApi } from "@/lib/admin";

/**
 * GET /api/v1/admin/subscriptions
 * Returns all subscription rows. Admin only.
 *
 * Query params:
 *   limit   number  (default 50)
 *   cursor  string  (created_at ISO timestamp)
 *   plan    string  filter by plan name
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "50"), 100);
    const cursor = searchParams.get("cursor") ?? undefined;
    const plan = searchParams.get("plan") ?? undefined;

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    let query = supabase
      .from("subscriptions")
      .select(`
        id, user_id, plan, status, start_date, end_date, auto_renew,
        trial_ends_at, stripe_customer_id, updated_at,
        users ( email, display_name )
      `)
      .order("start_date", { ascending: false })
      .limit(limit + 1);

    if (plan) query = query.eq("plan", plan);
    if (cursor) query = query.lt("start_date", cursor);

    const { data, error } = await query;
    if (error) throw error;

    const rows = data ?? [];
    const hasMore = rows.length > limit;
    const page = rows.slice(0, limit);

    return NextResponse.json({
      data: page,
      meta: { nextCursor: hasMore ? page[page.length - 1].start_date : null },
    });
  } catch (err) {
    console.error("[GET /api/v1/admin/subscriptions]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch subscriptions" } },
      { status: 500 }
    );
  }
}
