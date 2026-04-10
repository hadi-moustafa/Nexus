"use client";

import { useState, useEffect } from "react";

const REACTIONS = [
  { type: "like",  emoji: "👍" },
  { type: "love",  emoji: "❤️" },
  { type: "wow",   emoji: "😮" },
  { type: "sad",   emoji: "😢" },
  { type: "angry", emoji: "😡" },
] as const;

type ReactionType = (typeof REACTIONS)[number]["type"];

interface Props {
  articleId: string;
  /** userId of the currently signed-in user, or null if anonymous */
  currentUserId: string | null;
}

export function ReactionsBar({ articleId, currentUserId }: Props) {
  const [counts, setCounts] = useState<Record<string, number>>({});
  const [myReaction, setMyReaction] = useState<ReactionType | null>(null);
  const [loading, setLoading] = useState(true);
  const [pending, setPending] = useState(false);

  useEffect(() => {
    fetch(`/api/v1/articles/${articleId}/reactions`)
      .then((r) => r.json())
      .then(({ data }) => {
        setCounts(data?.counts ?? {});
        setMyReaction(data?.myReaction ?? null);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [articleId]);

  const handleReact = async (type: ReactionType) => {
    if (!currentUserId || pending) return;

    const prev = myReaction;
    const prevCounts = { ...counts };

    // Optimistic update
    if (myReaction === type) {
      // Toggle off
      setMyReaction(null);
      setCounts((c) => ({ ...c, [type]: Math.max(0, (c[type] ?? 1) - 1) }));
    } else {
      // Remove old reaction count if switching
      if (myReaction) {
        setCounts((c) => ({ ...c, [myReaction]: Math.max(0, (c[myReaction] ?? 1) - 1) }));
      }
      setMyReaction(type);
      setCounts((c) => ({ ...c, [type]: (c[type] ?? 0) + 1 }));
    }

    setPending(true);
    try {
      if (prev === type) {
        // Remove reaction
        const res = await fetch(`/api/v1/articles/${articleId}/reactions`, {
          method: "DELETE",
        });
        if (!res.ok && res.status !== 204) throw new Error();
      } else {
        // Upsert reaction
        const res = await fetch(`/api/v1/articles/${articleId}/reactions`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ type }),
        });
        if (!res.ok) throw new Error();
      }
    } catch {
      // Rollback on failure
      setMyReaction(prev);
      setCounts(prevCounts);
    } finally {
      setPending(false);
    }
  };

  const total = Object.values(counts).reduce((a, b) => a + b, 0);

  if (loading) {
    return (
      <div className="flex gap-2 animate-pulse">
        {REACTIONS.map((r) => (
          <div key={r.type} className="h-9 w-14 rounded-full bg-[var(--muted)]" />
        ))}
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2 flex-wrap">
      {REACTIONS.map(({ type, emoji }) => {
        const count = counts[type] ?? 0;
        const active = myReaction === type;
        return (
          <button
            key={type}
            onClick={() => handleReact(type)}
            disabled={!currentUserId || pending}
            title={currentUserId ? undefined : "Sign in to react"}
            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full border text-sm transition-all ${
              active
                ? "border-[var(--primary)] bg-[var(--primary)]/10 text-[var(--primary)] font-semibold"
                : "border-[var(--border)] bg-[var(--surface)] text-[var(--text-secondary)] hover:border-[var(--primary)]/40 hover:text-[var(--text-primary)]"
            } disabled:cursor-default`}
          >
            <span>{emoji}</span>
            {count > 0 && <span className="text-xs tabular-nums">{count}</span>}
          </button>
        );
      })}
      {total > 0 && (
        <span className="text-xs text-[var(--text-secondary)] ml-1">
          {total} {total === 1 ? "reaction" : "reactions"}
        </span>
      )}
    </div>
  );
}
