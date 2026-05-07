import { createServiceClient } from "@/lib/supabase/server";
import type { UserSession } from "@/types";

function parseUA(ua: string | null): { deviceName: string | null; browser: string | null } {
  if (!ua) return { deviceName: null, browser: null };
  let browser: string | null = null;
  if (ua.includes("Dart")) browser = "Flutter App";
  else if (ua.includes("Chrome")) browser = "Chrome";
  else if (ua.includes("Firefox")) browser = "Firefox";
  else if (ua.includes("Safari")) browser = "Safari";
  else if (ua.includes("Edge")) browser = "Edge";

  let deviceName: string | null = null;
  if (ua.includes("Android")) deviceName = "Android";
  else if (ua.includes("iPhone") || ua.includes("iPad")) deviceName = "iOS";
  else if (ua.includes("Windows")) deviceName = "Windows";
  else if (ua.includes("Mac")) deviceName = "macOS";
  else if (ua.includes("Linux")) deviceName = "Linux";

  return { deviceName, browser };
}

function rowToSession(
  row: Record<string, unknown>,
  currentFingerprint?: string
): UserSession {
  return {
    id: row.id as string,
    deviceName: (row.device_name as string | null) ?? null,
    browser: (row.browser as string | null) ?? null,
    ipAddress: (row.ip_address as string | null) ?? null,
    createdAt: row.created_at as string,
    lastActiveAt: row.last_active_at as string,
    isCurrent: currentFingerprint
      ? (row.user_agent as string | null) === currentFingerprint
      : false,
  };
}

/**
 * Creates a new session record on login, or updates last_active_at if the
 * same device (matched by user_agent) already has an active session.
 * Called fire-and-forget (void) — must not throw.
 */
/**
 * Creates a new session record on login, or updates last_active_at if the
 * same device (matched by user_agent) already has an active session.
 * Returns { isNew: true } when a new session was created (i.e., first login
 * from this device since last sign-out), which callers use to log sign_in events.
 */
export async function trackSession(
  userId: string,
  ipAddress: string | null,
  userAgent: string | null
): Promise<{ isNew: boolean }> {
  try {
    const supabase = createServiceClient();
    const { deviceName, browser } = parseUA(userAgent);

    const { data: existing } = await supabase
      .from("user_sessions")
      .select("id")
      .eq("user_id", userId)
      .eq("user_agent", userAgent ?? "")
      .is("revoked_at", null)
      .limit(1)
      .maybeSingle();

    if (existing?.id) {
      await supabase
        .from("user_sessions")
        .update({ last_active_at: new Date().toISOString(), ip_address: ipAddress })
        .eq("id", existing.id);
      return { isNew: false };
    }

    await supabase.from("user_sessions").insert({
      user_id: userId,
      device_name: deviceName,
      browser,
      ip_address: ipAddress,
      user_agent: userAgent,
    });
    return { isNew: true };
  } catch {
    return { isNew: false };
  }
}

export async function getUserSessions(
  userId: string,
  currentUserAgent?: string | null
): Promise<UserSession[]> {
  const supabase = createServiceClient();
  const { data, error } = await supabase
    .from("user_sessions")
    .select("*")
    .eq("user_id", userId)
    .is("revoked_at", null)
    .order("last_active_at", { ascending: false });

  if (error) throw error;
  return (data ?? []).map(r =>
    rowToSession(r as Record<string, unknown>, currentUserAgent ?? undefined)
  );
}

export async function revokeSession(
  sessionId: string,
  userId: string
): Promise<boolean> {
  const supabase = createServiceClient();
  const { error } = await supabase
    .from("user_sessions")
    .update({ revoked_at: new Date().toISOString() })
    .eq("id", sessionId)
    .eq("user_id", userId)
    .is("revoked_at", null);
  return !error;
}

export async function revokeAllSessions(userId: string): Promise<void> {
  const supabase = createServiceClient();
  await supabase
    .from("user_sessions")
    .update({ revoked_at: new Date().toISOString() })
    .eq("user_id", userId)
    .is("revoked_at", null);
}

export async function getAdminUserSessions(
  userId: string
): Promise<UserSession[]> {
  const supabase = createServiceClient();
  const { data, error } = await supabase
    .from("user_sessions")
    .select("*")
    .eq("user_id", userId)
    .order("last_active_at", { ascending: false })
    .limit(50);
  if (error) throw error;
  return (data ?? []).map(r => rowToSession(r as Record<string, unknown>));
}
