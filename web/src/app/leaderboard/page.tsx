"use client";

import { useState, useEffect } from "react";
import { Zap, ArrowRight, Crown, Star } from "lucide-react";
import Link from "next/link";
import { Navbar } from "@/components/layout/navbar";

interface LeaderboardEntry {
  userId: string;
  displayName: string;
  avatarUrl: string | null;
  totalXp: number;
  rank: number;
}

interface MyRank {
  rank: number;
  totalXp: number;
}

/* ── Avatar ────────────────────────────────────────────────────────────── */
const AVATAR_COLORS = [
  "from-violet-500 to-indigo-500",
  "from-emerald-500 to-teal-500",
  "from-rose-500 to-pink-500",
  "from-amber-500 to-orange-500",
  "from-sky-500 to-cyan-500",
];

function Avatar({ entry, size = "md" }: { entry: LeaderboardEntry; size?: "sm" | "md" | "lg" }) {
  const color = AVATAR_COLORS[entry.displayName.charCodeAt(0) % AVATAR_COLORS.length];
  const sz = size === "lg" ? "w-14 h-14 text-xl" : size === "md" ? "w-10 h-10 text-sm" : "w-8 h-8 text-xs";
  return (
    <div className={`${sz} rounded-full shrink-0 overflow-hidden`}>
      {entry.avatarUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img src={entry.avatarUrl} alt="" className="w-full h-full object-cover" />
      ) : (
        <div className={`w-full h-full bg-gradient-to-br ${color} flex items-center justify-center font-bold text-white`}>
          {entry.displayName.charAt(0).toUpperCase()}
        </div>
      )}
    </div>
  );
}

/* ── Podium card ────────────────────────────────────────────────────────── */
const PODIUM_META = [
  { rank: 2, height: "pt-8",  ring: "ring-slate-400/40",   badge: "bg-slate-400/20 text-slate-300",   label: "2nd" },
  { rank: 1, height: "pt-0",  ring: "ring-yellow-400/50",  badge: "bg-yellow-400/20 text-yellow-300", label: "1st" },
  { rank: 3, height: "pt-14", ring: "ring-amber-600/40",   badge: "bg-amber-600/20 text-amber-400",   label: "3rd" },
];

function PodiumCard({ entry, meta }: { entry: LeaderboardEntry; meta: typeof PODIUM_META[number] }) {
  return (
    <div className={`flex flex-col items-center gap-2 ${meta.height}`}>
      {meta.rank === 1 && (
        <Crown size={20} className="text-yellow-400 animate-pulse mb-0.5" />
      )}
      <div className={`ring-2 ${meta.ring} rounded-full`}>
        <Avatar entry={entry} size="lg" />
      </div>
      <p className="text-xs font-semibold text-[var(--text-primary)] text-center max-w-[80px] truncate">
        {entry.displayName}
      </p>
      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${meta.badge}`}>
        {meta.label}
      </span>
      <div className="flex items-center gap-1 text-xs font-bold text-[var(--primary)]">
        <Zap size={11} />
        {entry.totalXp.toLocaleString()}
      </div>
    </div>
  );
}

/* ── Row gradient for top 3 ─────────────────────────────────────────────── */
const ROW_HIGHLIGHT: Record<number, string> = {
  1: "bg-gradient-to-r from-yellow-500/10 to-transparent border-l-2 border-yellow-500/50",
  2: "bg-gradient-to-r from-slate-400/10 to-transparent border-l-2 border-slate-400/40",
  3: "bg-gradient-to-r from-amber-600/10 to-transparent border-l-2 border-amber-600/40",
};

const RANK_LABEL: Record<number, { text: string; color: string }> = {
  1: { text: "🥇", color: "text-yellow-400" },
  2: { text: "🥈", color: "text-slate-300" },
  3: { text: "🥉", color: "text-amber-500" },
};

/* ── Page ────────────────────────────────────────────────────────────────── */
export default function LeaderboardPage() {
  const [entries, setEntries] = useState<LeaderboardEntry[]>([]);
  const [myRank, setMyRank] = useState<MyRank | null>(null);
  const [loading, setLoading] = useState(true);
  const [nextOffset, setNextOffset] = useState<number | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);

  const fetchPage = async (offset: number) => {
    const res = await fetch(`/api/v1/leaderboard?limit=50&offset=${offset}`);
    if (!res.ok) return null;
    return res.json();
  };

  useEffect(() => {
    fetchPage(0)
      .then((json) => {
        if (!json) return;
        setEntries(json.data ?? []);
        setMyRank(json.meta?.myRank ?? null);
        setNextOffset((json.data?.length ?? 0) === 50 ? 50 : null);
      })
      .finally(() => setLoading(false));
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadMore = async () => {
    if (nextOffset === null || loadingMore) return;
    setLoadingMore(true);
    const json = await fetchPage(nextOffset);
    if (json) {
      setEntries((prev) => [...prev, ...(json.data ?? [])]);
      setNextOffset((json.data?.length ?? 0) === 50 ? nextOffset + 50 : null);
    }
    setLoadingMore(false);
  };

  const isMock = !loading && entries.length > 0 && entries[0].userId.startsWith("mock-");
  const top3 = entries.length >= 3 ? [entries[1], entries[0], entries[2]] : [];

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-2xl mx-auto px-5 pb-24 pt-8">

        {/* ── Header ───────────────────────────────────────────────── */}
        <div className="flex items-start justify-between mb-8">
          <div>
            <h1 className="font-display text-3xl font-bold text-[var(--text-primary)] tracking-tight">
              Leaderboard
            </h1>
            <p className="text-sm text-[var(--text-secondary)] mt-1">
              Top readers ranked by total XP
            </p>
          </div>
          <Link
            href="/quiz"
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 active:scale-95 transition-all shrink-0"
          >
            <Star size={14} />
            Today&apos;s quiz
            <ArrowRight size={13} />
          </Link>
        </div>

        {/* ── My rank banner ──────────────────────────────────────── */}
        {myRank && (
          <div className="mb-8 relative overflow-hidden rounded-2xl border border-[var(--primary)]/20 bg-gradient-to-r from-[var(--primary)]/10 via-[var(--primary)]/5 to-transparent p-4">
            <div className="absolute inset-0 bg-gradient-to-br from-[var(--primary)]/5 to-transparent pointer-events-none" />
            <div className="relative flex items-center gap-4">
              <div className="w-11 h-11 rounded-xl bg-[var(--primary)]/20 flex items-center justify-center shrink-0">
                <Zap size={20} className="text-[var(--primary)]" />
              </div>
              <div className="flex-1">
                <p className="text-[11px] font-semibold uppercase tracking-widest text-[var(--primary)] mb-0.5">
                  Your Standing
                </p>
                <div className="flex items-baseline gap-2">
                  <span className="text-2xl font-bold text-[var(--text-primary)]">
                    #{myRank.rank}
                  </span>
                  <span className="text-sm text-[var(--text-secondary)]">
                    {myRank.totalXp.toLocaleString()} XP earned
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* ── Podium ───────────────────────────────────────────────── */}
        {!loading && top3.length === 3 && (
          <div className="mb-8 rounded-2xl border border-[var(--border)] bg-gradient-to-b from-[var(--surface)] to-[var(--background)] p-6">
            <p className="text-[11px] font-bold uppercase tracking-widest text-[var(--text-secondary)] text-center mb-6">
              Top Performers
            </p>
            <div className="grid grid-cols-3 gap-4 items-end">
              {top3.map((entry, i) => (
                <PodiumCard key={entry.userId} entry={entry} meta={PODIUM_META[i]} />
              ))}
            </div>
          </div>
        )}

        {/* ── Full table ───────────────────────────────────────────── */}
        <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">

          {/* Table header */}
          <div className="flex items-center gap-4 px-5 py-2.5 border-b border-[var(--border)] bg-[var(--muted)]/40">
            <span className="w-7 text-[10px] font-bold uppercase tracking-wider text-[var(--text-secondary)] text-center">#</span>
            <span className="flex-1 text-[10px] font-bold uppercase tracking-wider text-[var(--text-secondary)]">Player</span>
            <span className="text-[10px] font-bold uppercase tracking-wider text-[var(--text-secondary)]">XP</span>
          </div>

          {loading ? (
            <div className="divide-y divide-[var(--border)]">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="flex items-center gap-4 px-5 py-3.5 animate-pulse">
                  <div className="w-7 h-4 rounded bg-[var(--muted)]" />
                  <div className="w-9 h-9 rounded-full bg-[var(--muted)]" />
                  <div className="flex-1 h-3 rounded bg-[var(--muted)]" />
                  <div className="w-20 h-3 rounded bg-[var(--muted)]" />
                </div>
              ))}
            </div>
          ) : entries.length === 0 ? (
            <div className="py-16 text-center">
              <p className="text-3xl mb-3">🏆</p>
              <p className="text-sm font-semibold text-[var(--text-primary)] mb-1">No rankings yet</p>
              <p className="text-xs text-[var(--text-secondary)]">Complete the daily quiz to claim your spot</p>
            </div>
          ) : (
            <div className="divide-y divide-[var(--border)]">
              {entries.map((e) => {
                const isMe = myRank && e.rank === myRank.rank && !isMock;
                const rankLabel = RANK_LABEL[e.rank];
                const rowHighlight = ROW_HIGHLIGHT[e.rank] ?? "";
                return (
                  <div
                    key={e.userId}
                    className={`flex items-center gap-4 px-5 py-3.5 transition-colors ${
                      isMe
                        ? "bg-[var(--primary)]/8 border-l-2 border-[var(--primary)]"
                        : rowHighlight || "hover:bg-[var(--muted)]/60"
                    }`}
                  >
                    {/* Rank */}
                    <div className="w-7 text-center shrink-0">
                      {rankLabel ? (
                        <span className="text-lg leading-none">{rankLabel.text}</span>
                      ) : (
                        <span className={`text-xs font-bold tabular-nums ${isMe ? "text-[var(--primary)]" : "text-[var(--text-secondary)]"}`}>
                          #{e.rank}
                        </span>
                      )}
                    </div>

                    {/* Avatar */}
                    <Avatar entry={e} size="sm" />

                    {/* Name */}
                    <p className={`flex-1 text-sm font-semibold truncate ${isMe ? "text-[var(--primary)]" : "text-[var(--text-primary)]"}`}>
                      {e.displayName}
                      {isMe && (
                        <span className="ml-2 text-[10px] font-bold bg-[var(--primary)]/15 text-[var(--primary)] px-1.5 py-0.5 rounded-full align-middle">
                          you
                        </span>
                      )}
                    </p>

                    {/* XP */}
                    <div className="flex items-center gap-1.5 shrink-0">
                      <Zap size={12} className="text-[var(--primary)]" />
                      <span className="text-sm font-bold text-[var(--text-primary)] tabular-nums">
                        {e.totalXp.toLocaleString()}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Load more */}
        {nextOffset !== null && (
          <button
            onClick={loadMore}
            disabled={loadingMore}
            className="mt-4 w-full py-3 rounded-xl border border-[var(--border)] text-sm font-semibold text-[var(--text-secondary)] hover:bg-[var(--muted)] hover:text-[var(--text-primary)] disabled:opacity-40 transition-all"
          >
            {loadingMore ? "Loading…" : "Load more"}
          </button>
        )}

        {/* Mock data notice */}
        {isMock && (
          <p className="mt-5 text-center text-xs text-[var(--text-secondary)] opacity-50">
            Sample data — your name appears here once you complete a quiz
          </p>
        )}

      </main>
    </div>
  );
}
