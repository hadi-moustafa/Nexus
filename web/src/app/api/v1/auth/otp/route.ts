import { type NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import * as crypto from "crypto";
import { createClient, createServiceClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";
import { trackSession } from "@/lib/db/sessions";
import { sendMail } from "@/lib/mailer";
import { otpEmailHtml } from "@/lib/email-templates";
import { rateLimit, getClientIp, rateLimitResponse } from "@/lib/rate-limit";

function generateOtp(): string {
  return String(crypto.randomInt(0, 1_000_000)).padStart(6, "0");
}

function hashOtp(code: string): string {
  return crypto.createHash("sha256").update(code).digest("hex");
}

/**
 * POST /api/v1/auth/otp
 *
 * action = "send"
 *   Generate a 6-digit OTP, store its hash, and email it via SMTP.
 *   Body: { action: "send", email: string }
 *
 * action = "verify"
 *   Verify the OTP, create the Supabase user account, sign them in,
 *   and return session tokens (for mobile) + set cookies (for web).
 *   Body: { action: "verify", email: string, token: string, password: string }
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { action, email: rawEmail, token, password } = body as {
      action: "send" | "verify";
      email?: string;
      token?: string;
      password?: string;
    };

    const email = rawEmail?.trim().toLowerCase() ?? "";

    if (!email) {
      return NextResponse.json(
        { error: { code: "VALIDATION_ERROR", message: "email is required" } },
        { status: 400 }
      );
    }

    const ip = getClientIp(request);
    const service = createServiceClient();

    // ── Send ────────────────────────────────────────────────────────────────────
    if (action === "send") {
      // 3 sends per IP per 15 minutes
      const rl = rateLimit(`otp:send:${ip}`, 3, 15 * 60 * 1000);
      if (!rl.ok) return rateLimitResponse(rl.resetAt) as NextResponse;
      // Guard: don't send OTP to an already-registered email
      const { data: existing } = await service
        .from("users")
        .select("id")
        .eq("email", email)
        .maybeSingle();

      if (existing) {
        return NextResponse.json(
          { error: { code: "EMAIL_EXISTS", message: "An account with this email already exists." } },
          { status: 409 }
        );
      }

      // Clean up any prior unused codes for this email
      await service
        .from("otp_codes")
        .delete()
        .eq("email", email)
        .is("used_at", null);

      const code = generateOtp();
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();

      // Dev fallback: print the code to the terminal so it's usable even when
      // SMTP is blocked by a firewall (common in local dev environments).
      if (process.env.NODE_ENV !== "production") {
        console.log(`\n┌─ OTP CODE ──────────────────────────────┐`);
        console.log(`│  Email : ${email}`);
        console.log(`│  Code  : ${code}`);
        console.log(`└────────────────────────────────────────┘\n`);
      }

      const { error: insertErr } = await service.from("otp_codes").insert({
        email,
        code_hash: hashOtp(code),
        expires_at: expiresAt,
      });

      if (insertErr) {
        console.error("[otp/send] DB insert failed:", insertErr.message);
        return NextResponse.json(
          { error: { code: "INTERNAL_ERROR", message: "Failed to create verification code" } },
          { status: 500 }
        );
      }

      // Fire-and-forget — a send failure doesn't block sign-up (code is logged above in dev)
      sendMail({
        to: email,
        subject: "Your Nexus verification code",
        html: otpEmailHtml(code),
      }).catch((err) => console.error("[otp/send] SMTP failed:", err));

      void logAction("otp_requested", null, { email }, request);
      return NextResponse.json({ data: { sent: true } });
    }

    // ── Verify ──────────────────────────────────────────────────────────────────
    if (action === "verify") {
      // 10 verify attempts per email per 15 minutes — prevents brute-force
      const rl = rateLimit(`otp:verify:${email}`, 10, 15 * 60 * 1000);
      if (!rl.ok) return rateLimitResponse(rl.resetAt) as NextResponse;
      if (!token || typeof token !== "string") {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "token is required" } },
          { status: 400 }
        );
      }
      if (!password || typeof password !== "string") {
        return NextResponse.json(
          { error: { code: "VALIDATION_ERROR", message: "password is required" } },
          { status: 400 }
        );
      }

      const invalid = () =>
        NextResponse.json(
          { error: { code: "INVALID_OTP", message: "Invalid or expired code. Please try again." } },
          { status: 422 }
        );

      // Find the latest unused, unexpired code for this email
      const { data: record } = await service
        .from("otp_codes")
        .select("id, code_hash, expires_at")
        .eq("email", email)
        .is("used_at", null)
        .gt("expires_at", new Date().toISOString())
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      if (!record) return invalid();

      const inputHash = hashOtp(token.trim());
      if (inputHash !== record.code_hash) return invalid();

      // Mark the code as used
      await service
        .from("otp_codes")
        .update({ used_at: new Date().toISOString() })
        .eq("id", record.id);

      // Create or update the Supabase Auth user.
      // The user may already exist in auth.users if they previously started sign-up
      // via Supabase's own confirmation flow. In that case createUser returns their
      // existing record without updating the password, so we must update it explicitly.
      // OTP verification proves email ownership, so a password reset is safe here.
      let userId: string | undefined;

      const { data: created, error: createErr } = await service.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

      if (!createErr && created.user) {
        userId = created.user.id;
      } else {
        // User already exists in auth.users — look up their ID from public.users
        // and update their password + confirm status (OTP proves ownership).
        const { data: existingRow } = await service
          .from("users")
          .select("id")
          .eq("email", email)
          .maybeSingle();

        if (!existingRow?.id) {
          console.error("[otp/verify] createUser failed and user not in public.users:", createErr?.message);
          return NextResponse.json(
            { error: { code: "INTERNAL_ERROR", message: "Failed to create account" } },
            { status: 500 }
          );
        }

        userId = existingRow.id as string;
        const { error: updateErr } = await service.auth.admin.updateUserById(userId, {
          password,
          email_confirm: true,
        });

        if (updateErr) {
          console.error("[otp/verify] updateUserById failed:", updateErr.message);
          return NextResponse.json(
            { error: { code: "INTERNAL_ERROR", message: "Failed to set up account" } },
            { status: 500 }
          );
        }
      }

      // Sign the user in to establish a session (sets cookies for web)
      const cookieStore = await cookies();
      const supabase = createClient(cookieStore);
      const { data: signInData, error: signInErr } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (signInErr || !signInData.session) {
        console.error("[otp/verify] signIn failed:", signInErr?.message);
        return NextResponse.json(
          { error: { code: "INTERNAL_ERROR", message: "Account created but sign-in failed. Please sign in manually." } },
          { status: 500 }
        );
      }

      const uid = userId ?? signInData.user.id;
      void logAction("otp_verified", uid, { email }, request);
      void logAction("sign_up", uid, { method: "email", email }, request);
      void trackSession(
        uid,
        request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? null,
        request.headers.get("user-agent")
      );

      return NextResponse.json({
        data: {
          verified: true,
          userId: uid,
          // Include tokens in the response body so the mobile app can store them
          accessToken: signInData.session.access_token,
          refreshToken: signInData.session.refresh_token,
        },
      });
    }

    return NextResponse.json(
      { error: { code: "VALIDATION_ERROR", message: "action must be 'send' or 'verify'" } },
      { status: 400 }
    );
  } catch (err) {
    console.error("[POST /api/v1/auth/otp]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "OTP operation failed" } },
      { status: 500 }
    );
  }
}
