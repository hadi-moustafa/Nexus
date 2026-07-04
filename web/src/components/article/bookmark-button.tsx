"use client";

import { useState } from "react";
import { Bookmark } from "lucide-react";

interface Props {
  articleId: string;
  initialBookmarked: boolean;
}

export function BookmarkButton({ articleId, initialBookmarked }: Props) {
  const [bookmarked, setBookmarked] = useState(initialBookmarked);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const toggle = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      if (bookmarked) {
        const res = await fetch(
          `/api/v1/user/bookmarks?articleId=${encodeURIComponent(articleId)}`,
          { method: "DELETE" }
        );
        if (res.ok || res.status === 204) {
          setBookmarked(false);
        } else {
          const json = await res.json().catch(() => ({}));
          setErrorMsg((json as { error?: { message?: string } }).error?.message ?? "Failed to remove bookmark");
        }
      } else {
        const res = await fetch("/api/v1/user/bookmarks", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ articleId }),
        });
        if (res.ok || res.status === 201) {
          setBookmarked(true);
        } else {
          const json = await res.json().catch(() => ({}));
          setErrorMsg((json as { error?: { message?: string } }).error?.message ?? "Failed to save bookmark");
        }
      }
    } catch {
      setErrorMsg("Something went wrong");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative shrink-0">
      <button
        onClick={toggle}
        disabled={loading}
        title={bookmarked ? "Remove bookmark" : "Save article"}
        className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-sm font-medium transition-all disabled:opacity-50 ${
          bookmarked
            ? "bg-[var(--primary)]/15 text-[var(--primary)] border border-[var(--primary)]/30"
            : "border border-[var(--border)] text-[var(--text-secondary)] hover:text-[var(--primary)] hover:border-[var(--primary)]/40"
        }`}
      >
        <Bookmark
          size={15}
          className={bookmarked ? "fill-[var(--primary)]" : ""}
        />
        {bookmarked ? "Saved" : "Save"}
      </button>
      {errorMsg && (
        <p className="absolute top-full mt-1.5 right-0 text-xs text-red-500 bg-[var(--surface)] border border-red-200 dark:border-red-900 rounded-lg px-2.5 py-1.5 whitespace-nowrap z-10 shadow-sm">
          {errorMsg}
        </p>
      )}
    </div>
  );
}
