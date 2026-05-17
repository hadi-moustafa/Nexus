"use client";

import { useState, useEffect } from "react";
import { Plus, BadgeCheck, Star, Award, Trash2, Link, Unlink, FileText } from "lucide-react";

interface Badge {
  id: string;
  badge_type: string;
  awarded_at: string;
}

interface Journalist {
  id: string;
  name: string;
  bio: string | null;
  byline_match: string | null;
  is_verified: boolean;
  follower_count: number;
  post_count: number;
  user_id: string | null;
  linkedUserEmail: string | null;
  journalist_badges: Badge[];
  created_at: string;
}

const BADGE_META: Record<string, { label: string; color: string; icon: string }> = {
  rising_star: { label: "Rising Star",  color: "text-yellow-500 bg-yellow-500/10",  icon: "⭐" },
  popular:     { label: "Popular",      color: "text-orange-500 bg-orange-500/10",  icon: "🔥" },
  gold:        { label: "Gold",         color: "text-amber-500 bg-amber-500/10",    icon: "🏆" },
  prolific:    { label: "Prolific",     color: "text-blue-500 bg-blue-500/10",      icon: "📝" },
  verified:    { label: "Verified",     color: "text-teal-500 bg-teal-500/10",      icon: "✓" },
  featured:    { label: "Featured",     color: "text-purple-500 bg-purple-500/10",  icon: "★" },
};

const AWARDABLE_BADGES = ["verified", "featured", "rising_star", "popular", "gold", "prolific"];

export default function AdminJournalistsPage() {
  const [journalists, setJournalists] = useState<Journalist[]>([]);
  const [loading, setLoading] = useState(true);
  const [acting, setActing] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ name: "", byline_match: "", bio: "", user_id: "" });
  const [adding, setAdding] = useState(false);
  const [expanded, setExpanded] = useState<string | null>(null);
  const [linkUserId, setLinkUserId] = useState<Record<string, string>>({});

  useEffect(() => {
    fetch("/api/v1/admin/journalists")
      .then((r) => r.json())
      .then(({ data }) => setJournalists(data ?? []))
      .finally(() => setLoading(false));
  }, []);

  const patch = async (id: string, body: Record<string, unknown>) => {
    setActing(id);
    const res = await fetch(`/api/v1/admin/journalists/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });
    if (res.ok) {
      const { data, badge } = await res.json();
      setJournalists((prev) =>
        prev.map((j) => {
          if (j.id !== id) return j;
          const updated = { ...j, ...(data ?? {}) };
          if (badge?.action === "awarded") {
            updated.journalist_badges = [...j.journalist_badges.filter((b) => b.badge_type !== badge.badge.badge_type), badge.badge];
          } else if (badge?.action === "revoked") {
            updated.journalist_badges = j.journalist_badges.filter((b) => b.badge_type !== badge.badgeType);
          }
          return updated;
        })
      );
    }
    setActing(null);
  };

  const deleteJournalist = async (id: string) => {
    if (!confirm("Delete this journalist profile? All their posts will also be deleted.")) return;
    setActing(id);
    const res = await fetch(`/api/v1/admin/journalists/${id}`, { method: "DELETE" });
    if (res.ok) setJournalists((prev) => prev.filter((j) => j.id !== id));
    setActing(null);
  };

  const addJournalist = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) return;
    setAdding(true);
    const res = await fetch("/api/v1/admin/journalists", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: form.name.trim(),
        byline_match: form.byline_match.trim() || null,
        bio: form.bio.trim() || null,
        user_id: form.user_id.trim() || null,
      }),
    });
    if (res.ok) {
      const { data } = await res.json();
      setJournalists((prev) => [data, ...prev]);
      setForm({ name: "", byline_match: "", bio: "", user_id: "" });
      setShowForm(false);
    }
    setAdding(false);
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)]">Journalists</h1>
        <button
          onClick={() => setShowForm((v) => !v)}
          className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 transition-opacity"
        >
          <Plus size={15} />
          Add journalist
        </button>
      </div>

      {showForm && (
        <form
          onSubmit={addJournalist}
          className="mb-6 p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] flex flex-col gap-3"
        >
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <input
              value={form.name}
              onChange={(e) => setForm((f) => ({ ...f, name: e.target.value }))}
              placeholder="Full name *"
              required
              className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
            />
            <input
              value={form.byline_match}
              onChange={(e) => setForm((f) => ({ ...f, byline_match: e.target.value }))}
              placeholder="Byline match"
              className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
            />
          </div>
          <input
            value={form.user_id}
            onChange={(e) => setForm((f) => ({ ...f, user_id: e.target.value }))}
            placeholder="Link to user ID (optional — grants journalist role)"
            className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
          />
          <textarea
            value={form.bio}
            onChange={(e) => setForm((f) => ({ ...f, bio: e.target.value }))}
            placeholder="Short bio (optional)"
            rows={2}
            className="px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)] resize-none"
          />
          <button
            type="submit"
            disabled={adding}
            className="self-end px-4 py-2 rounded-lg bg-[var(--primary)] text-white text-sm font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
          >
            {adding ? "Adding…" : "Add"}
          </button>
        </form>
      )}

      <div className="flex flex-col gap-3">
        {loading
          ? Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="p-4 rounded-2xl border border-[var(--border)] bg-[var(--surface)] animate-pulse">
                <div className="h-4 w-40 rounded bg-[var(--muted)] mb-2" />
                <div className="h-3 w-64 rounded bg-[var(--muted)]" />
              </div>
            ))
          : journalists.map((j) => (
              <div
                key={j.id}
                className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden"
              >
                {/* Row */}
                <div className="flex items-start gap-3 p-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1">
                      <span className="font-semibold text-[var(--text-primary)] text-sm">{j.name}</span>
                      {j.is_verified && <BadgeCheck size={14} className="text-[var(--primary)] shrink-0" />}
                      {j.journalist_badges.map((b) => {
                        const meta = BADGE_META[b.badge_type];
                        if (!meta) return null;
                        return (
                          <span key={b.id} className={`text-[10px] px-1.5 py-0.5 rounded-full font-medium ${meta.color}`}>
                            {meta.icon} {meta.label}
                          </span>
                        );
                      })}
                    </div>
                    <div className="flex items-center gap-3 text-xs text-[var(--text-secondary)] flex-wrap">
                      <span className="flex items-center gap-1"><Star size={11} />{j.follower_count.toLocaleString()} followers</span>
                      <span className="flex items-center gap-1"><FileText size={11} />{j.post_count} posts</span>
                      {j.linkedUserEmail ? (
                        <span className="flex items-center gap-1 text-green-500"><Link size={11} />{j.linkedUserEmail}</span>
                      ) : (
                        <span className="flex items-center gap-1 text-[var(--text-secondary)]"><Unlink size={11} />No account linked</span>
                      )}
                    </div>
                    {j.bio && <p className="text-xs text-[var(--text-secondary)] mt-1 line-clamp-1">{j.bio}</p>}
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      onClick={() => patch(j.id, { is_verified: !j.is_verified })}
                      disabled={acting === j.id}
                      className={`text-xs px-2.5 py-1 rounded-lg border transition-colors disabled:opacity-50 ${
                        j.is_verified
                          ? "border-[var(--primary)]/40 text-[var(--primary)]"
                          : "border-[var(--border)] text-[var(--text-secondary)] hover:text-[var(--primary)] hover:border-[var(--primary)]/40"
                      }`}
                    >
                      {j.is_verified ? "Unverify" : "Verify"}
                    </button>
                    <button
                      onClick={() => setExpanded((v) => (v === j.id ? null : j.id))}
                      className="text-xs px-2.5 py-1 rounded-lg border border-[var(--border)] text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
                    >
                      <Award size={12} />
                    </button>
                    <button
                      onClick={() => deleteJournalist(j.id)}
                      disabled={acting === j.id}
                      className="text-xs px-2.5 py-1 rounded-lg text-red-500 hover:bg-red-500/5 hover:border-red-400/50 border border-transparent transition-colors disabled:opacity-50"
                    >
                      <Trash2 size={12} />
                    </button>
                  </div>
                </div>

                {/* Expanded badge + link panel */}
                {expanded === j.id && (
                  <div className="px-4 pb-4 pt-0 border-t border-[var(--border)] space-y-3">
                    {/* Badge management */}
                    <div>
                      <p className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide mb-2 mt-3">Manage Badges</p>
                      <div className="flex flex-wrap gap-2">
                        {AWARDABLE_BADGES.map((bt) => {
                          const has = j.journalist_badges.some((b) => b.badge_type === bt);
                          const meta = BADGE_META[bt];
                          return (
                            <button
                              key={bt}
                              disabled={acting === j.id}
                              onClick={() => patch(j.id, has ? { revoke_badge: bt } : { award_badge: bt })}
                              className={`text-xs px-2.5 py-1 rounded-lg border transition-all disabled:opacity-50 ${
                                has
                                  ? `border-transparent ${meta.color} opacity-100`
                                  : "border-[var(--border)] text-[var(--text-secondary)] hover:border-[var(--primary)]/40 hover:text-[var(--primary)]"
                              }`}
                            >
                              {meta.icon} {meta.label} {has ? "✕" : "+"}
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    {/* Link user */}
                    <div>
                      <p className="text-xs font-medium text-[var(--text-secondary)] uppercase tracking-wide mb-2">Link User Account</p>
                      <div className="flex gap-2">
                        <input
                          value={linkUserId[j.id] ?? ""}
                          onChange={(e) => setLinkUserId((prev) => ({ ...prev, [j.id]: e.target.value }))}
                          placeholder="Paste user UUID…"
                          className="flex-1 px-3 py-1.5 rounded-lg border border-[var(--border)] bg-[var(--background)] text-xs text-[var(--text-primary)] focus:outline-none focus:border-[var(--primary)]"
                        />
                        <button
                          disabled={acting === j.id || !linkUserId[j.id]?.trim()}
                          onClick={() => patch(j.id, { user_id: linkUserId[j.id]?.trim() || null })}
                          className="text-xs px-3 py-1.5 rounded-lg bg-[var(--primary)] text-white disabled:opacity-50 hover:opacity-90 transition-opacity"
                        >
                          Link
                        </button>
                        {j.user_id && (
                          <button
                            disabled={acting === j.id}
                            onClick={() => patch(j.id, { user_id: null })}
                            className="text-xs px-3 py-1.5 rounded-lg border border-red-400/40 text-red-500 hover:bg-red-500/5 disabled:opacity-50 transition-colors"
                          >
                            Unlink
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                )}
              </div>
            ))}
        {!loading && journalists.length === 0 && (
          <p className="text-sm text-[var(--text-secondary)] text-center py-10">No journalist profiles yet.</p>
        )}
      </div>
    </div>
  );
}
