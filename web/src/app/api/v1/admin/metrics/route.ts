import { type NextRequest, NextResponse } from "next/server";
import { requireAdminApi } from "@/lib/admin";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/admin/metrics
 * Returns user growth and activity metrics for the admin dashboard.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAdminApi(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const supabase = createServiceClient();
    const now = new Date();
    const ago7 = new Date(now.getTime() - 7 * 86400000).toISOString();
    const ago30 = new Date(now.getTime() - 30 * 86400000).toISOString();

    const [
      { count: totalUsers },
      { count: newLast7 },
      { count: newLast30 },
      { count: googleUsers },
      { count: emailUsers },
      { count: adminUsers },
      { count: bannedUsers },
      { count: activeLast7 },
    ] = await Promise.all([
      supabase.from("users").select("*", { count: "exact", head: true }),
      supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", ago7),
      supabase.from("users").select("*", { count: "exact", head: true }).gte("created_at", ago30),
      supabase.from("users").select("*", { count: "exact", head: true }).eq("auth_provider", "google"),
      supabase.from("users").select("*", { count: "exact", head: true }).eq("auth_provider", "email"),
      supabase.from("users").select("*", { count: "exact", head: true }).eq("role", "admin"),
      supabase.from("users").select("*", { count: "exact", head: true }).eq("role", "banned"),
      supabase.from("audit_log").select("*", { count: "exact", head: true })
        .eq("action", "sign_in")
        .gte("created_at", ago7),
    ]);

    // Daily sign-ups for the last 30 days
    const { data: dailyData } = await supabase
      .from("users")
      .select("created_at")
      .gte("created_at", ago30)
      .order("created_at", { ascending: true });

    const byDay: Record<string, number> = {};
    for (const row of dailyData ?? []) {
      const day = (row.created_at as string).slice(0, 10);
      byDay[day] = (byDay[day] ?? 0) + 1;
    }

    // Fill in zero days for the last 30 days
    const signUpsByDay = [];
    for (let i = 29; i >= 0; i--) {
      const d = new Date(now.getTime() - i * 86400000);
      const key = d.toISOString().slice(0, 10);
      signUpsByDay.push({ date: key, count: byDay[key] ?? 0 });
    }

    return NextResponse.json({
      data: {
        totalUsers: totalUsers ?? 0,
        newUsersLast7Days: newLast7 ?? 0,
        newUsersLast30Days: newLast30 ?? 0,
        activeUsersLast7Days: activeLast7 ?? 0,
        googleUsers: googleUsers ?? 0,
        emailUsers: emailUsers ?? 0,
        adminUsers: adminUsers ?? 0,
        bannedUsers: bannedUsers ?? 0,
        signUpsByDay,
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/admin/metrics]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch metrics" } },
      { status: 500 }
    );
  }
}
