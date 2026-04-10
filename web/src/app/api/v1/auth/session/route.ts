import { type NextRequest } from "next/server";
import { cookies } from "next/headers";
import { requireAuth } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { getUserProfile } from "@/lib/db/users";

/**
 * GET /api/v1/auth/session
 *
 * Returns the authenticated user's profile + auth provider, or 401 if not signed in.
 * `provider` is "google" for OAuth users or "email" for password-based users.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth; // 401

  try {
    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);
    const { data: { user: authUser } } = await supabase.auth.getUser();
    const provider = authUser?.app_metadata?.provider ?? "email";

    const profile = await getUserProfile(auth.userId);

    if (!profile) {
      return Response.json({
        data: {
          id: auth.userId,
          email: auth.email ?? null,
          displayName: null,
          avatarUrl: null,
          createdAt: new Date().toISOString(),
          provider,
        },
      });
    }

    return Response.json({ data: { ...profile, provider } });
  } catch (err) {
    console.error("[GET /api/v1/auth/session]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch session" } },
      { status: 500 }
    );
  }
}
