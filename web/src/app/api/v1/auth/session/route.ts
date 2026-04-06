import { type NextRequest } from "next/server";
import { requireAuth } from "@/lib/auth";
import { getUserProfile } from "@/lib/db/users";

/**
 * GET /api/v1/auth/session
 *
 * Returns the authenticated user's profile, or 401 if not signed in.
 * Used by the mobile app on launch to validate a stored access token.
 *
 * Web:    reads session cookie (handled by middleware + Supabase SSR)
 * Mobile: reads Authorization: Bearer <access_token> header
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth; // 401

  try {
    const profile = await getUserProfile(auth.userId);

    if (!profile) {
      // Auth user exists but public.users row is missing (trigger hasn't run yet
      // or was skipped). Return minimal profile from auth data.
      return Response.json({
        data: {
          id: auth.userId,
          email: auth.email ?? null,
          displayName: null,
          avatarUrl: null,
          createdAt: new Date().toISOString(),
        },
      });
    }

    return Response.json({ data: profile });
  } catch (err) {
    console.error("[GET /api/v1/auth/session]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch session" } },
      { status: 500 }
    );
  }
}
