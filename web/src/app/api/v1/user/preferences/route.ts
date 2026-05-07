import { type NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth";
import { getUserPreferences, updateUserPreferences } from "@/lib/db/users";
import { logAction } from "@/lib/audit";

/**
 * GET /api/v1/user/preferences
 * Returns the authenticated user's preferences.
 */
export async function GET(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const prefs = await getUserPreferences(auth.userId);
    if (!prefs) {
      // Row not yet seeded — return sensible defaults
      return NextResponse.json({
        data: { topics: [], preferredLanguage: "en", onboardingComplete: false },
      });
    }
    return NextResponse.json({ data: prefs });
  } catch (err) {
    console.error("[GET /api/v1/user/preferences]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch preferences" } },
      { status: 500 }
    );
  }
}

/**
 * PATCH /api/v1/user/preferences
 * Partial update — only provided fields are written.
 *
 * Body (all optional):
 *   { topics?: string[], preferredLanguage?: string, onboardingComplete?: boolean }
 */
export async function PATCH(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof NextResponse) return auth;

  try {
    const body = await request.json();
    const patch: { topics?: string[]; preferredLanguage?: string; onboardingComplete?: boolean } =
      {};

    if (Array.isArray(body.topics)) patch.topics = body.topics;
    if (typeof body.preferredLanguage === "string") patch.preferredLanguage = body.preferredLanguage;
    if (typeof body.onboardingComplete === "boolean")
      patch.onboardingComplete = body.onboardingComplete;

    const updated = await updateUserPreferences(auth.userId, patch);
    void logAction("preferences_updated", auth.userId, patch as Record<string, unknown>, request);
    return NextResponse.json({ data: updated });
  } catch (err) {
    console.error("[PATCH /api/v1/user/preferences]", err);
    return NextResponse.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to update preferences" } },
      { status: 500 }
    );
  }
}
