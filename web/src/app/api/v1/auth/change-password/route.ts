import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";
import { logAction } from "@/lib/audit";

/**
 * POST /api/v1/auth/change-password
 *
 * Updates the user's password.
 * - Email users: must provide currentPassword for verification.
 * - OAuth-only users (e.g. Google): currentPassword is not required —
 *   they are setting a password for the first time.
 *
 * Body: { newPassword: string, currentPassword?: string }
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const body = await request.json();
    const { newPassword, currentPassword } = body as {
      newPassword?: string;
      currentPassword?: string;
    };

    if (!newPassword || newPassword.length < 8) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "New password must be at least 8 characters" } },
        { status: 400 }
      );
    }

    const cookieStore = await cookies();
    const supabase = createClient(cookieStore);

    // Check whether this user has an email/password identity
    const { data: { user } } = await supabase.auth.getUser();
    const hasEmailIdentity = user?.identities?.some((i) => i.provider === "email") ?? false;

    if (hasEmailIdentity) {
      // Email user must verify their current password first
      if (!currentPassword) {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "Current password is required" } },
          { status: 400 }
        );
      }

      const { error: signInErr } = await supabase.auth.signInWithPassword({
        email: user!.email!,
        password: currentPassword,
      });

      if (signInErr) {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "Current password is incorrect" } },
          { status: 400 }
        );
      }
    }

    const { error } = await supabase.auth.updateUser({ password: newPassword });
    if (error) throw error;

    void logAction("password_changed", auth.userId, {}, request);
    return NextResponse.json({ data: { success: true } });
  } catch (err) {
    console.error("[POST /api/v1/auth/change-password]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update password" } },
      { status: 500 }
    );
  }
}
