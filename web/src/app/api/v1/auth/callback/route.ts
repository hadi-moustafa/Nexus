import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";

/**
 * GET /api/v1/auth/callback
 *
 * OAuth code exchange handler. Supabase redirects here after Google
 * consent with a one-time `code` query param. This route exchanges it
 * for a session cookie and redirects the user into the app.
 *
 * The `redirectTo` option in signInWithOAuth() must point to this URL.
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

  // For new users (first sign-in), redirect to onboarding
  if (sessionData?.user) {
    const { data: prefs } = await supabase
      .from("user_preferences")
      .select("onboarding_complete")
      .eq("user_id", sessionData.user.id)
      .single();

    if (!prefs || !prefs.onboarding_complete) {
      return NextResponse.redirect(`${origin}/onboarding`);
    }
  }

  // Redirect to the originally intended destination, or feed
  return NextResponse.redirect(`${origin}${next === "/" ? "/feed" : next}`);
}
