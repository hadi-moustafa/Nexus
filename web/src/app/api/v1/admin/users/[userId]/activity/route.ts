import { type NextRequest, NextResponse } from "next/server";
import { requireAdminApi } from "@/lib/admin";
import { createServiceClient } from "@/lib/supabase/server";

interface RouteContext {
  params: Promise<{ userId: string }>;
}

/**
 * GET /api/v1/admin/users/[userId]/activity
 * Returns the audit log for a specific user. Admin only.
 * Query params: limit (default 50), cursor (created_at ISO for pagination)
 */
export async function GET(request: NextRequest, { params }: RouteContext) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const { userId } = await params;
    const url = new URL(request.url);
    const limit = Math.min(parseInt(url.searchParams.get("limit") ?? "50"), 100);
    const cursor = url.searchParams.get("cursor");

    const supabase = createServiceClient();
    let query = supabase
      .from("audit_log")
      .select("id, user_id, action, metadata, ip_address, user_agent, created_at")
      .eq("user_id", userId)
      .order("created_at", { ascending: false })
      .limit(limit + 1);

    if (cursor) {
      query = query.lt("created_at", cursor);
    }

    const { data, error } = await query;
    if (error) throw error;

    const hasMore = (data?.length ?? 0) > limit;
    const rows = (data ?? []).slice(0, limit);
    const nextCursor = hasMore ? rows[rows.length - 1]?.created_at : null;

    return NextResponse.json({
      data: rows.map(r => ({
        id: r.id,
        userId: r.user_id,
        action: r.action,
        metadata: r.metadata,
        ipAddress: r.ip_address,
        userAgent: r.user_agent,
        createdAt: r.created_at,
      })),
      meta: { nextCursor },
    });
  } catch (err) {
    console.error("[GET /api/v1/admin/users/[userId]/activity]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch activity" } },
      { status: 500 }
    );
  }
}
