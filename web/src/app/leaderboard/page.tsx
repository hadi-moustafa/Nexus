"use client";

import { useState, useEffect } from "react";
import { Trophy, Medal, Zap, ArrowRight } from "lucide-react";
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

const RANK_COLORS: Record<number, string> = {
  1: "text-yellow-500",
  2: "text-slate-400",
  3: "text-amber-600",
};

const RANK_ICONS: Record<number, React.ReactNode> = {
  1: <Trophy size={16} className="text-yellow-500" />,
  2: <Medal size={16} className="text-slate-400" />,
  3: <Medal size={16} className="text-amber-600" />,
};

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
        setNextOffset(json.data?.length === 50 ? 50 : null);
      })
      .finally(() => setLoading(false));
  }, []);

  const loadMore = async () => {
    if (nextOffset === null || loadingMore) return;
    setLoadingMore(true);
    const json = await fetchPage(nextOffset);
    if (json) {
      setEntries((prev) => [...prev, ...(json.data ?? [])]);
      setNextOffset(json.data?.length === 50 ? nextOffset + 50 : null);
    }
    setLoadingMore(false);
  };

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-2xl mx-auto px-5 pb-24 pt-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)]">
              Leaderboard
            </h1>
            <p className="text-xs text-[var(--text-secondary)] mt-0.5">Ranked by total XP</p>
          </div>
          <Link
            href="/quiz"
            className="flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
          >
            Today&apos;s quiz
            <ArrowRight size={14} />
          </Link>
        </div>

        {/* My rank banner */}
        {myRank && (
          <div className="mb-6 flex items-center gap-3 p-4 rounded-2xl border border-[var(--primary)]/30 bg-[var(--primary)]/5">
            <Zap size={18} className="text-[var(--primary)] shrink-0" />
            <div>
              <p className="text-sm font-semibold text-[var(--text-primary)]">
                Your rank: #{myRank.rank}
              </p>
              <p className="text-xs text-[var(--text-secondary)]">
                {myRank.totalXp.toLocaleString()} XP total
              </p>
            </div>
          </div>
        )}

        {/* Top 3 podium */}
        {!loading && entries.length >= 3 && (
          <div className="grid grid-cols-3 gap-3 mb-6">
            {[entries[1], entries[0], entries[2]].map((e, podiumIdx) => {
              const actualRank = podiumIdx === 0 ? 2 : podiumIdx === 1 ? 1 : 3;
              const heights = ["h-24", "h-32", "h-20"];
              return (
                <div key={e.userId} className="flex flex-col items-center gap-2">
                  <div className="w-10 h-10 rounded-full bg-[var(--primary)] flex items-center justify-center overflow-hidden shrink-0">
                    {e.avatarUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={e.avatarUrl} alt="" className="w-full h-full object-cover" />
                    ) : (
                      <span className="text-sm font-bold text-white">
                        {e.displayName.charAt(0).toUpperCase()}
                      </span>
                    )}
                  </div>
                  <p className="text-xs font-medium text-[var(--text-primary)] text-center truncate w-full text-center">
                    {e.displayName}
                  </p>
                  <div
                    className={`w-full ${heights[podiumIdx]} rounded-t-xl flex flex-col items-center justify-center gap-1 ${
                      actualRank === 1
                        ? "bg-yellow-500/20 border-2 border-yellow-500/40"
                        : actualRank === 2
                        ? "bg-slate-400/10 border-2 border-slate-400/30"
                        : "bg-amber-600/10 border-2 border-amber-600/30"
                    }`}
                  >
                    {RANK_ICONS[actualRank]}
                    <span className={`text-xs font-bold ${RANK_COLORS[actualRank]}`}>
                      #{actualRank}
                    </span>
                    <span className="text-xs text-[var(--text-secondary)]">
                      {e.totalXp.toLocaleString()} XP
                    </span>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {/* Full table */}
        <div className="rounded-2xl border border-[var(--border)] bg-[var(--surface)] overflow-hidden">
          {loading ? (
            <div className="divide-y divide-[var(--border)]">
              {Array.from({ length: 8 }).map((_, i) => (
                <div key={i} className="flex items-center gap-4 px-5 py-3 animate-pulse">
                  <div className="w-6 h-3 rounded bg-[var(--muted)]" />
                  <div className="w-8 h-8 rounded-full bg-[var(--muted)]" />
                  <div className="flex-1 h-3 rounded bg-[var(--muted)]" />
                  <div className="w-16 h-3 rounded bg-[var(--muted)]" />
                </div>
              ))}
            </div>
          ) : (
            <div className="divide-y divide-[var(--border)]">
              {entries.map((e) => (
                <div
                  key={e.userId}
                  className={`flex items-center gap-4 px-5 py-3 transition-colors ${
                    myRank && e.rank === myRank.rank
                      ? "bg-[var(--primary)]/5"
                      : "hover:bg-[var(--muted)]"
                  }`}
                >
                  {/* Rank */}
                  <div className={`w-7 text-sm font-bold tabular-nums shrink-0 ${RANK_COLORS[e.rank] ?? "text-[var(--text-secondary)]"}`}>
                    {RANK_ICONS[e.rank] ?? `#${e.rank}`}
                  </div>

                  {/* Avatar */}
                  <div className="w-9 h-9 rounded-full bg-[var(--primary)] flex items-center justify-center overflow-hidden shrink-0">
                    {e.avatarUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={e.avatarUrl} alt="" className="w-full h-full object-cover" />
                    ) : (
                      <span className="text-xs font-bold text-white">
                        {e.displayName.charAt(0).toUpperCase()}
                      </span>
                    )}
                  </div>

                  {/* Name */}
                  <p className="flex-1 text-sm font-medium text-[var(--text-primary)] truncate">
                    {e.displayName}
                  </p>

                  {/* XP */}
                  <div className="flex items-center gap-1 text-sm font-semibold text-[var(--primary)] shrink-0">
                    <Zap size={13} />
                    {e.totalXp.toLocaleString()}
                  </div>
                </div>
              ))}
            </div>
          )}

          {!loading && entries.length === 0 && (
            <p className="text-sm text-[var(--text-secondary)] text-center py-12">
              No entries yet. Take the quiz to get on the board!
            </p>
          )}
        </div>

        {nextOffset !== null && (
          <button
            onClick={loadMore}
            disabled={loadingMore}
            className="mt-4 text-sm text-[var(--primary)] hover:underline disabled:opacity-50"
          >
            {loadingMore ? "Loading…" : "Load more"}
          </button>
        )}
      </main>
    </div>
  );
}
