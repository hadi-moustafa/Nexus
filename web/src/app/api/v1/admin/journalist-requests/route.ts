import { NextRequest, NextResponse } from "next/server";
import { requireAdminApi } from "@/lib/admin";
import { createServiceClient } from "@/lib/supabase/server";

// GET /api/v1/admin/journalist-requests?status=pending|approved|rejected|all
export async function GET(req: NextRequest) {
  const guard = await requireAdminApi(req);
  if (guard instanceof NextResponse) return guard;

  const { searchParams } = new URL(req.url);
  const status = searchParams.get("status") ?? "pending";
  const limit = Math.min(parseInt(searchParams.get("limit") ?? "50", 10), 100);

  const supabase = createServiceClient();

  let query = supabase
    .from("journalist_requests")
    .select("id, user_id, status, message, admin_note, reviewed_by, created_at, reviewed_at")
    .order("created_at", { ascending: false })
    .limit(limit);

  if (status !== "all") {
    query = query.eq("status", status);
  }

  const { data: requests, error } = await query;
  if (error) {
    return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: error.message } }, { status: 500 });
  }

  if (!requests || requests.length === 0) {
    return NextResponse.json({ data: [] });
  }

  // Enrich with user display info
  const userIds = [...new Set(requests.map((r) => r.user_id))];
  const { data: users } = await supabase
    .from("users")
    .select("id, email, display_name")
    .in("id", userIds);

  const userMap = new Map((users ?? []).map((u) => [u.id, u]));

  const enriched = requests.map((r) => {
    const u = userMap.get(r.user_id);
    return {
      id: r.id,
      userId: r.user_id,
      userEmail: u?.email ?? "unknown",
      userDisplayName: u?.display_name ?? null,
      status: r.status,
      message: r.message,
      adminNote: r.admin_note,
      reviewedBy: r.reviewed_by,
      createdAt: r.created_at,
      reviewedAt: r.reviewed_at,
    };
  });

  return NextResponse.json({ data: enriched });
}
