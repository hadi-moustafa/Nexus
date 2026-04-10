import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { type NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

/**
 * Server-component guard. Redirects to / if the caller is not an admin.
 * Use at the top of admin page components.
 */
export async function requireAdminPage(): Promise<string> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/");

  const { data } = await supabase
    .from("users")
    .select("role")
    .eq("id", user.id)
    .single();

  if (data?.role !== "admin") redirect("/");
  return user.id;
}

/**
 * Route-handler guard. Returns a 403 NextResponse if the caller is not an admin.
 * Use at the top of admin API route handlers.
 */
export async function requireAdminApi(
  request: NextRequest
): Promise<{ userId: string } | NextResponse> {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  // Support Bearer token (mobile) as well as cookies (web)
  const authHeader = request.headers.get("authorization");
  let user = null;
  if (authHeader?.startsWith("Bearer ")) {
    const { data } = await supabase.auth.getUser(authHeader.slice(7));
    user = data.user;
  } else {
    const { data } = await supabase.auth.getUser();
    user = data.user;
  }

  if (!user) {
    return NextResponse.json(
      { error: { code: "UNAUTHORIZED", message: "Not authenticated" } },
      { status: 401 }
    );
  }

  const { data } = await supabase
    .from("users")
    .select("role")
    .eq("id", user.id)
    .single();

  if (data?.role !== "admin") {
    return NextResponse.json(
      { error: { code: "FORBIDDEN", message: "Admin access required" } },
      { status: 403 }
    );
  }

  return { userId: user.id };
}
