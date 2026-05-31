"use client";

import { useEffect, useState, useCallback } from "react";
import { CheckCircle, XCircle, Clock, User, MessageSquare, RefreshCw } from "lucide-react";

type Status = "pending" | "approved" | "rejected" | "all";

interface JRequest {
  id: string;
  userId: string;
  userEmail: string;
  userDisplayName: string | null;
  status: "pending" | "approved" | "rejected";
  message: string | null;
  adminNote: string | null;
  reviewedBy: string | null;
  createdAt: string;
  reviewedAt: string | null;
}

const STATUS_TABS: { label: string; value: Status }[] = [
  { label: "Pending", value: "pending" },
  { label: "Approved", value: "approved" },
  { label: "Rejected", value: "rejected" },
  { label: "All", value: "all" },
];

function statusChip(status: string) {
  if (status === "pending")
    return (
      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400">
        <Clock size={11} /> Pending
      </span>
    );
  if (status === "approved")
    return (
      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
        <CheckCircle size={11} /> Approved
      </span>
    );
  return (
    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400">
      <XCircle size={11} /> Rejected
    </span>
  );
}

export default function JournalistRequestsPage() {
  const [tab, setTab] = useState<Status>("pending");
  const [requests, setRequests] = useState<JRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [noteInputs, setNoteInputs] = useState<Record<string, string>>({});
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);

  const showToast = (msg: string, ok = true) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3500);
  };

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/v1/admin/journalist-requests?status=${tab}&limit=100`);
      const json = await res.json();
      setRequests(json.data ?? []);
    } catch {
      showToast("Failed to load requests.", false);
    } finally {
      setLoading(false);
    }
  }, [tab]);

  useEffect(() => { load(); }, [load]);

  async function act(id: string, action: "approve" | "reject") {
    setActionLoading(id + action);
    try {
      const res = await fetch(`/api/v1/admin/journalist-requests/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action, adminNote: noteInputs[id] ?? "" }),
      });
      const json = await res.json();
      if (!res.ok) throw new Error(json.error?.message ?? "Error");
      showToast(action === "approve" ? "Request approved — user is now a journalist." : "Request rejected.");
      setExpanded(null);
      load();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error", false);
    } finally {
      setActionLoading(null);
    }
  }

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Toast */}
      {toast && (
        <div
          className={`fixed top-4 right-4 z-50 px-4 py-3 rounded-lg shadow-lg text-sm font-medium ${
            toast.ok ? "bg-emerald-600 text-white" : "bg-red-600 text-white"
          }`}
        >
          {toast.msg}
        </div>
      )}

      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-display font-semibold text-[var(--text-primary)]">
            Journalist Requests
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mt-1">
            Review user applications to become journalists.
          </p>
        </div>
        <button
          onClick={load}
          className="flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-lg border border-[var(--border)] hover:bg-[var(--muted)] transition-colors"
        >
          <RefreshCw size={14} />
          Refresh
        </button>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 border-b border-[var(--border)]">
        {STATUS_TABS.map((t) => (
          <button
            key={t.value}
            onClick={() => { setTab(t.value); setExpanded(null); }}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px ${
              tab === t.value
                ? "border-[var(--primary)] text-[var(--primary)]"
                : "border-transparent text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* List */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="h-24 rounded-xl bg-[var(--muted)] animate-pulse" />
          ))}
        </div>
      ) : requests.length === 0 ? (
        <div className="text-center py-16 text-[var(--text-secondary)]">
          <User size={40} className="mx-auto mb-3 opacity-30" />
          <p className="text-sm">No {tab !== "all" ? tab : ""} requests.</p>
        </div>
      ) : (
        <div className="space-y-3">
          {requests.map((r) => (
            <div
              key={r.id}
              className="rounded-xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden"
            >
              {/* Header row */}
              <div className="flex items-start gap-3 p-4">
                <div className="w-9 h-9 rounded-full bg-[var(--muted)] flex items-center justify-center shrink-0 text-sm font-semibold text-[var(--text-primary)]">
                  {(r.userDisplayName ?? r.userEmail)[0].toUpperCase()}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-[var(--text-primary)] text-sm truncate">
                    {r.userDisplayName ?? "—"}
                  </p>
                  <p className="text-xs text-[var(--text-secondary)] truncate">{r.userEmail}</p>
                  <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                    {new Date(r.createdAt).toLocaleDateString(undefined, {
                      year: "numeric", month: "short", day: "numeric",
                    })}
                  </p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  {statusChip(r.status)}
                  {r.message && (
                    <button
                      onClick={() => setExpanded(expanded === r.id ? null : r.id)}
                      className="p-1.5 rounded-lg hover:bg-[var(--muted)] transition-colors"
                      title="View message"
                    >
                      <MessageSquare size={14} className="text-[var(--text-secondary)]" />
                    </button>
                  )}
                </div>
              </div>

              {/* Expanded panel */}
              {expanded === r.id && (
                <div className="px-4 pb-4 border-t border-[var(--border)] pt-3 space-y-3">
                  {r.message && (
                    <div>
                      <p className="text-xs font-semibold text-[var(--text-secondary)] uppercase tracking-wide mb-1">
                        Applicant message
                      </p>
                      <p className="text-sm text-[var(--text-primary)] bg-[var(--muted)] rounded-lg px-3 py-2 whitespace-pre-wrap">
                        {r.message}
                      </p>
                    </div>
                  )}

                  {r.adminNote && (
                    <div>
                      <p className="text-xs font-semibold text-[var(--text-secondary)] uppercase tracking-wide mb-1">
                        Admin note
                      </p>
                      <p className="text-sm text-[var(--text-primary)] bg-[var(--muted)] rounded-lg px-3 py-2">
                        {r.adminNote}
                      </p>
                    </div>
                  )}

                  {r.status === "pending" && (
                    <>
                      <div>
                        <label className="text-xs font-semibold text-[var(--text-secondary)] uppercase tracking-wide block mb-1">
                          Note (optional)
                        </label>
                        <textarea
                          rows={2}
                          maxLength={500}
                          placeholder="Add a note for the user (shown on rejection)…"
                          value={noteInputs[r.id] ?? ""}
                          onChange={(e) => setNoteInputs((p) => ({ ...p, [r.id]: e.target.value }))}
                          className="w-full text-sm bg-[var(--background)] border border-[var(--border)] rounded-lg px-3 py-2 resize-none focus:outline-none focus:ring-1 focus:ring-[var(--primary)]"
                        />
                      </div>
                      <div className="flex gap-2">
                        <button
                          disabled={actionLoading !== null}
                          onClick={() => act(r.id, "approve")}
                          className="flex items-center gap-1.5 px-4 py-2 text-sm font-medium rounded-lg bg-emerald-600 text-white hover:bg-emerald-700 disabled:opacity-50 transition-colors"
                        >
                          <CheckCircle size={14} />
                          {actionLoading === r.id + "approve" ? "Approving…" : "Approve"}
                        </button>
                        <button
                          disabled={actionLoading !== null}
                          onClick={() => act(r.id, "reject")}
                          className="flex items-center gap-1.5 px-4 py-2 text-sm font-medium rounded-lg bg-red-600 text-white hover:bg-red-700 disabled:opacity-50 transition-colors"
                        >
                          <XCircle size={14} />
                          {actionLoading === r.id + "reject" ? "Rejecting…" : "Reject"}
                        </button>
                      </div>
                    </>
                  )}
                </div>
              )}

              {/* Expand toggle if no message but is pending */}
              {r.status === "pending" && !r.message && expanded !== r.id && (
                <div className="px-4 pb-3">
                  <button
                    onClick={() => setExpanded(r.id)}
                    className="text-xs text-[var(--primary)] hover:underline"
                  >
                    Review &amp; act
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
