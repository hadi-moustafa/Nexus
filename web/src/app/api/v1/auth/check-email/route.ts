import { type NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

/**
 * POST /api/v1/auth/check-email
 * Body: { email: string }
 * Returns: { data: { exists: boolean } }
 *
 * Used by the sign-up form to detect existing accounts before sending an OTP,
 * so we can prompt the user to sign in instead.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const email = (body?.email ?? "").trim().toLowerCase();

    if (!email) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "email is required" } },
        { status: 400 }
      );
    }

    const service = createServiceClient();
    const { data } = await service
      .from("users")
      .select("id")
      .eq("email", email)
      .maybeSingle();

    return NextResponse.json({ data: { exists: !!data } });
  } catch (err) {
    console.error("[POST /api/v1/auth/check-email]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to check email" } },
      { status: 500 }
    );
  }
}
