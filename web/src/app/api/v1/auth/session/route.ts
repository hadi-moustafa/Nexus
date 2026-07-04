import { type NextRequest } from "next/server";
import { requireAuth } from "@/lib/auth";
import { createServiceClient } from "@/lib/supabase/server";
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

  // Provider info comes from app_metadata already returned by requireAuth's
  // getUser() call — no second admin.getUserById round-trip needed.
  const provider = (auth.appMetadata?.provider as string) ?? "email";

  try {
    const supabase = createServiceClient();
    const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null;
    const ua = request.headers.get("user-agent");

    // Fetch profile (including role) and track session in parallel.
    const [{ data: profileRow }, { isNew }] = await Promise.all([
      supabase
        .from("users")
        .select("id, email, display_name, avatar_url, created_at, role")
        .eq("id", auth.userId)
        .maybeSingle(),
      trackSession(auth.userId, ip, ua),
    ]);

    if (!profileRow) {
      // No DB row yet — create all three rows now (idempotent upserts).
      // This covers mobile users where auth/callback is never called.
      const um = auth.userMetadata;
      await Promise.all([
        supabase.from("users").upsert(
          {
            id: auth.userId,
            email: auth.email,
            display_name: (um.full_name ?? um.name ?? null) as string | null,
            avatar_url: (um.avatar_url ?? um.picture ?? null) as string | null,
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
            total_xp: 0, current_streak: 0, longest_streak: 0,
            quizzes_completed: 0, perfect_scores: 0, articles_read: 0,
          },
          { onConflict: "user_id", ignoreDuplicates: true }
        ),
      ]);

      // Re-fetch with role after upsert
      const { data: freshRow } = await supabase
        .from("users")
        .select("id, email, display_name, avatar_url, created_at, role")
        .eq("id", auth.userId)
        .maybeSingle();

      if (!freshRow) {
        return Response.json({
          data: {
            id: auth.userId, email: auth.email ?? null,
            displayName: null, avatarUrl: null,
            createdAt: new Date().toISOString(),
            provider, isAdmin: false, role: "user", journalistId: null,
          },
        });
      }

      const role = (freshRow.role as string) ?? "user";
      return Response.json({
        data: {
          id: freshRow.id, email: freshRow.email,
          displayName: (freshRow.display_name as string | null) ?? null,
          avatarUrl: (freshRow.avatar_url as string | null) ?? null,
          createdAt: freshRow.created_at as string,
          provider, isAdmin: role === "admin", role, journalistId: null,
        },
      });
    }

    const role = (profileRow.role as string) ?? "user";
    const isAdmin = role === "admin";

    if (isNew && provider === "email") {
      void logAction("sign_in", auth.userId, { method: "email" }, request);
    }

    // Journalist id only needed for journalist role — rare, non-blocking
    let journalistId: string | null = null;
    if (role === "journalist") {
      const { data: jRow } = await supabase
        .from("journalists")
        .select("id")
        .eq("user_id", auth.userId)
        .maybeSingle();
      journalistId = jRow?.id ?? null;
    }

    return Response.json({
      data: {
        id: profileRow.id, email: profileRow.email,
        displayName: (profileRow.display_name as string | null) ?? null,
        avatarUrl: (profileRow.avatar_url as string | null) ?? null,
        createdAt: profileRow.created_at as string,
        provider, isAdmin, role, journalistId,
      },
    });
  } catch (err) {
    console.error("[GET /api/v1/auth/session]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch session" } },
      { status: 500 }
    );
  }
}
