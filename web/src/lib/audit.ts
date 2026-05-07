import { createServiceClient } from "@/lib/supabase/server";
import type { AuditAction } from "@/types";
import type { NextRequest } from "next/server";

function getClientIP(request: NextRequest): string | null {
  return (
    request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
    request.headers.get("x-real-ip") ??
    null
  );
}

export async function logAction(
  action: AuditAction,
  userId: string | null,
  metadata: Record<string, unknown> = {},
  request?: NextRequest
): Promise<void> {
  try {
    const supabase = createServiceClient();
    await supabase.from("audit_log").insert({
      user_id: userId,
      action,
      metadata,
      ip_address: request ? getClientIP(request) : null,
      user_agent: request ? (request.headers.get("user-agent") ?? null) : null,
    });
  } catch {
    // Audit logging must never break the main request
  }
}
