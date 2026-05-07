import { type NextRequest } from "next/server";
import { requireAuth } from "@/lib/auth";
import { createServiceClient } from "@/lib/supabase/server";
import { getUserProfile } from "@/lib/db/users";
import { logAction } from "@/lib/audit";
import { trackSession } from "@/lib/db/sessions";

/**
 * GET /api/v1/auth/session
 *
 * Returns the authenticated user's profile + auth provider, or 401 if not signed in.
 * Works for both web (cookie session) and mobile (Bearer token).
 *
 * Also performs belt-and-suspenders row creation: if the user has no row in
 * public.users/user_preferences/user_stats yet (trigger slow or not applied),
 * we create them here. This is the single endpoint every client calls right
 * after sign-in, so it's the safest place to guarantee DB rows exist.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth; // 401

  try {
    const supabase = createServiceClient();

    // Get auth metadata (provider) — requires service-role admin API so it
    // works for both cookie-based web sessions and Bearer-token mobile calls.
    const { data: { user: authUser } } = await supabase.auth.admin.getUserById(auth.userId);
    const provider = authUser?.app_metadata?.provider ?? "email";

    let profile = await getUserProfile(auth.userId);

    if (!profile) {
      // No DB row yet — create all three rows now (idempotent upserts).
      // This covers mobile users where auth/callback is never called.
      await Promise.all([
        supabase.from("users").upsert(
          {
            id: auth.userId,
            email: auth.email,
            display_name:
              authUser?.user_metadata?.full_name ??
              authUser?.user_metadata?.name ??
              null,
            avatar_url:
              authUser?.user_metadata?.avatar_url ??
              authUser?.user_metadata?.picture ??
              null,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "id" }
        ),
        supabase.from("user_preferences").upsert(
          { user_id: auth.userId, topics: [], preferred_language: "en", onboarding_complete: false },
          { onConflict: "user_id", ignoreDuplicates: true }
        ),
        supabase.from("user_stats").upsert(
          {
            user_id: auth.userId,
            total_xp: 0,
            current_streak: 0,
            longest_streak: 0,
            quizzes_completed: 0,
            perfect_scores: 0,
            articles_read: 0,
          },
          { onConflict: "user_id", ignoreDuplicates: true }
        ),
      ]);

      // Re-fetch so we return the freshly-created row
      profile = await getUserProfile(auth.userId);
    }

    if (!profile) {
      // Extremely unlikely — upsert succeeded but read returned nothing.
      // Return a synthetic profile so the client can proceed.
      return Response.json({
        data: {
          id: auth.userId,
          email: auth.email ?? null,
          displayName: null,
          avatarUrl: null,
          createdAt: new Date().toISOString(),
          provider,
          isAdmin: false,
        },
      });
    }

    const { data: roleRow } = await supabase
      .from("users")
      .select("role")
      .eq("id", auth.userId)
      .single();
    const isAdmin = roleRow?.role === "admin";

    // Track session; only log sign_in when it's a genuinely new session
    // (i.e., first request from this device since last sign-out).
    // OAuth sign-ins are already logged in /api/v1/auth/callback.
    const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null;
    const ua = request.headers.get("user-agent");
    const { isNew } = await trackSession(auth.userId, ip, ua);
    if (isNew && provider === "email") {
      void logAction("sign_in", auth.userId, { method: "email" }, request);
    }

    return Response.json({ data: { ...profile, provider, isAdmin } });
  } catch (err) {
    console.error("[GET /api/v1/auth/session]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch session" } },
      { status: 500 }
    );
  }
}
