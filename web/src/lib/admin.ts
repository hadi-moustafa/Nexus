import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { type NextRequest, NextResponse } from "next/server";
import { createClient, createServiceClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

/**
 * Server-component guard. Redirects to /login if the caller is not an admin.
 * Use at the top of admin page server components.
 */
export async function requireAdminPage(): Promise<string> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  // Service client bypasses RLS — safe because we already verified identity above.
  const service = createServiceClient();
  const { data } = await service
    .from("users")
    .select("role")
    .eq("id", user.id)
    .single();

  if (data?.role !== "admin") redirect("/");
  return user.id;
}

/**
 * Route-handler guard. Returns a 403 NextResponse if the caller is not an admin.
 * Works for both web (cookie session) and mobile (Bearer token).
 */
export async function requireAdminApi(
  request: NextRequest
): Promise<{ userId: string } | NextResponse> {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth; // 401

  const service = createServiceClient();
  const { data } = await service
    .from("users")
    .select("role")
    .eq("id", auth.userId)
    .single();

  if (data?.role !== "admin") {
    return NextResponse.json(
      { error: { code: "FORBIDDEN", message: "Admin access required" } },
      { status: 403 }
    );
  }

  return { userId: auth.userId };
}
