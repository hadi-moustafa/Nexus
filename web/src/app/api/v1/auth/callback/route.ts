import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient, createServiceClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";
import { trackSession } from "@/lib/db/sessions";
import { sendMail } from "@/lib/mailer";
import { welcomeEmailHtml } from "@/lib/email-templates";

/**
 * GET /api/v1/auth/callback
 *
 * OAuth code exchange handler. Supabase redirects here after Google
 * consent with a one-time `code` query param. This route exchanges it
 * for a session cookie and redirects the user into the app.
 */
export async function GET(request: NextRequest) {
  const { searchParams, origin } = request.nextUrl;
  const code = searchParams.get("code");
  const next = searchParams.get("next") ?? "/";

  if (!code) {
    return NextResponse.redirect(`${origin}/login?error=missing_code`);
  }

  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);

  const { data: sessionData, error } = await supabase.auth.exchangeCodeForSession(code);

  if (error) {
    console.error("[auth/callback] exchangeCodeForSession failed:", error.message);
    return NextResponse.redirect(`${origin}/login?error=auth_failed`);
  }

  if (sessionData?.user) {
    const user = sessionData.user;

    // Belt-and-suspenders: ensure DB rows exist even if the trigger was slow
    // or hadn't fired yet. All upserts are idempotent.
    const service = createServiceClient();
    await Promise.all([
      service.from("users").upsert(
        {
          id: user.id,
          email: user.email,
          display_name:
            user.user_metadata?.full_name ??
            user.user_metadata?.name ??
            null,
          avatar_url:
            user.user_metadata?.avatar_url ??
            user.user_metadata?.picture ??
            null,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "id" }
      ),
      service.from("user_preferences").upsert(
        { user_id: user.id, topics: [], preferred_language: "en", onboarding_complete: false },
        { onConflict: "user_id", ignoreDuplicates: true }
      ),
      service.from("user_stats").upsert(
        {
          user_id: user.id,
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

    // Check onboarding status using service client (bypasses RLS, always works)
    const { data: prefs } = await service
      .from("user_preferences")
      .select("onboarding_complete")
      .eq("user_id", user.id)
      .single();

    const isNewUser = !prefs?.onboarding_complete;
    void logAction(isNewUser ? "sign_up" : "sign_in", user.id, { method: "google" }, request);
    void trackSession(user.id, request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null, request.headers.get("user-agent"));

    if (isNewUser && user.email) {
      const name =
        user.user_metadata?.full_name ?? user.user_metadata?.name ?? null;
      void sendMail({
        to: user.email,
        subject: "Welcome to Nexus",
        html: welcomeEmailHtml(name),
      }).catch((err) => console.error("[callback] welcome email failed:", err));
    }

    if (!prefs?.onboarding_complete) {
      return NextResponse.redirect(`${origin}/onboarding`);
    }
  }

  return NextResponse.redirect(`${origin}${next === "/" ? "/feed" : next}`);
}
