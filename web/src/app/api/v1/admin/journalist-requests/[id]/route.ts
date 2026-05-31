import { NextRequest, NextResponse } from "next/server";
import { requireAdminApi } from "@/lib/admin";
import { createServiceClient } from "@/lib/supabase/server";
import { logAction } from "@/lib/audit";

// PATCH /api/v1/admin/journalist-requests/[id]
// body: { action: "approve" | "reject", adminNote?: string }
export async function PATCH(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const guard = await requireAdminApi(req);
  if (guard instanceof NextResponse) return guard;
  const admin = guard;

  const { id } = await params;
  const body = await req.json().catch(() => ({}));
  const action = body.action as string | undefined;
  const adminNote = typeof body.adminNote === "string" ? body.adminNote.trim().slice(0, 500) : null;

  if (action !== "approve" && action !== "reject") {
    return NextResponse.json(
      { error: { code: "VALIDATION_ERROR", message: 'action must be "approve" or "reject"' } },
      { status: 400 }
    );
  }

  const supabase = createServiceClient();

  // Fetch the request
  const { data: jrq, error: fetchErr } = await supabase
    .from("journalist_requests")
    .select("id, user_id, status")
    .eq("id", id)
    .maybeSingle();

  if (fetchErr) {
    console.error("[journalist-requests PATCH] fetch request:", fetchErr);
    return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: fetchErr.message } }, { status: 500 });
  }
  if (!jrq) {
    return NextResponse.json({ error: { code: "NOT_FOUND", message: "Request not found." } }, { status: 404 });
  }
  if (jrq.status !== "pending") {
    return NextResponse.json(
      { error: { code: "VALIDATION_ERROR", message: `Request is already ${jrq.status}.` } },
      { status: 409 }
    );
  }

  const now = new Date().toISOString();

  if (action === "reject") {
    const { error } = await supabase
      .from("journalist_requests")
      .update({
        status: "rejected",
        admin_note: adminNote,
        reviewed_by: admin.userId,
        reviewed_at: now,
      })
      .eq("id", id);

    if (error) {
      return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: error.message } }, { status: 500 });
    }

    await logAction("journalist_request_rejected", admin.userId, { requestId: id, targetUserId: jrq.user_id }, req);

    return NextResponse.json({ data: { id, status: "rejected" } });
  }

  // ── APPROVE ────────────────────────────────────────────────────────────────

  // 1. Fetch user info to populate journalist profile
  const { data: userRow } = await supabase
    .from("users")
    .select("id, email, display_name, avatar_url")
    .eq("id", jrq.user_id)
    .single();

  if (!userRow) {
    return NextResponse.json({ error: { code: "NOT_FOUND", message: "User not found." } }, { status: 404 });
  }

  // 2. Check if journalist profile already exists for this user
  const { data: existingJournalist } = await supabase
    .from("journalists")
    .select("id")
    .eq("user_id", jrq.user_id)
    .maybeSingle();

  let journalistId: string;

  if (existingJournalist) {
    journalistId = existingJournalist.id;
  } else {
    // 3. Create journalist profile
    const { data: newJournalist, error: createErr } = await supabase
      .from("journalists")
      .insert({
        name: userRow.display_name || userRow.email.split("@")[0],
        bio: null,
        byline_match: null,
        user_id: jrq.user_id,
      })
      .select("id")
      .single();

    if (createErr) {
      console.error("[journalist-requests PATCH] create journalist profile:", createErr);
      return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: createErr.message } }, { status: 500 });
    }
    journalistId = newJournalist.id;
  }

  // 4. Promote user role to journalist
  const { error: roleErr } = await supabase
    .from("users")
    .update({ role: "journalist" })
    .eq("id", jrq.user_id);

  if (roleErr) {
    console.error("[journalist-requests PATCH] promote user role:", roleErr);
    return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: roleErr.message } }, { status: 500 });
  }

  // 5. Mark request approved
  const { error: updateErr } = await supabase
    .from("journalist_requests")
    .update({
      status: "approved",
      admin_note: adminNote,
      reviewed_by: admin.userId,
      reviewed_at: now,
    })
    .eq("id", id);

  if (updateErr) {
    console.error("[journalist-requests PATCH] mark approved:", updateErr);
    return NextResponse.json({ error: { code: "INTERNAL_ERROR", message: updateErr.message } }, { status: 500 });
  }

  await logAction("journalist_request_approved", admin.userId, { requestId: id, targetUserId: jrq.user_id, journalistId }, req);

  return NextResponse.json({ data: { id, status: "approved", journalistId } });
}
