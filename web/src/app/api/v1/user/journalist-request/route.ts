import { NextRequest, NextResponse } from "next/server";
import { requireAuth } from "@/lib/auth";
import { createServiceClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";

// GET — fetch current user's journalist request status
export async function GET(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const supabase = createServiceClient();
  const { data, error } = await supabase
    .from("journalist_requests")
    .select("id, status, message, admin_note, created_at, reviewed_at")
    .eq("user_id", auth.userId)
    .maybeSingle();

  if (error) {
    return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: error.message } }, { status: 500 });
  }

  if (!data) {
    return NextResponse.json({ data: null });
  }

  return NextResponse.json({
    data: {
      id: data.id,
      status: data.status,
      message: data.message,
      adminNote: data.admin_note,
      createdAt: data.created_at,
      reviewedAt: data.reviewed_at,
    },
  });
}

// POST — submit or re-submit a journalist request
export async function POST(req: NextRequest) {
  const auth = await requireAuth(req);
  if (auth instanceof NextResponse) return auth;

  const supabase = createServiceClient();

  // Fetch the user's role to gate the request
  const { data: userRow } = await supabase
    .from("users")
    .select("role")
    .eq("id", auth.userId)
    .single();

  if (userRow?.role === "journalist") {
    return NextResponse.json(
      { error: { code: "FORBIDDEN", message: "You are already a journalist." } },
      { status: 403 }
    );
  }
  if (userRow?.role === "banned") {
    return NextResponse.json(
      { error: { code: "FORBIDDEN", message: "Your account has been suspended." } },
      { status: 403 }
    );
  }

  const body = await req.json().catch(() => ({}));
  const message = typeof body.message === "string" ? body.message.trim().slice(0, 1000) : null;

  // Check for an existing pending request to avoid duplicate confusion
  const { data: existing } = await supabase
    .from("journalist_requests")
    .select("id, status")
    .eq("user_id", auth.userId)
    .maybeSingle();

  if (existing?.status === "pending") {
    return NextResponse.json(
      { error: { code: "VALIDATION_ERROR", message: "You already have a pending request." } },
      { status: 409 }
    );
  }
  if (existing?.status === "approved") {
    return NextResponse.json(
      { error: { code: "VALIDATION_ERROR", message: "Your request was already approved." } },
      { status: 409 }
    );
  }

  // Upsert (replace rejected request with a new one)
  const { data, error } = await supabase
    .from("journalist_requests")
    .upsert(
      {
        user_id: auth.userId,
        status: "pending",
        message: message || null,
        admin_note: null,
        reviewed_by: null,
        reviewed_at: null,
        created_at: new Date().toISOString(),
      },
      { onConflict: "user_id" }
    )
    .select("id, status, created_at")
    .single();

  if (error) {
    return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: error.message } }, { status: 500 });
  }

  await logAction("journalist_request_submitted", auth.userId, { requestId: data.id }, req);

  return NextResponse.json({ data: { id: data.id, status: data.status, createdAt: data.created_at } }, { status: 201 });
}
