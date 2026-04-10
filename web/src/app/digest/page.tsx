"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Sparkles, ArrowRight, Lock, ExternalLink } from "lucide-react";
import Link from "next/link";
import { Navbar } from "@/components/layout/navbar";

interface DigestStory {
  title: string;
  summary: string;
  category: string;
  url: string;
  articleId: string;
}

interface Digest {
  id: string;
  cohort_key: string;
  digest_date: string;
  introduction: string;
  stories: DigestStory[];
  article_count: number;
  generated_at: string;
}

function formatDigestDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
    year: "numeric",
  });
}

export default function DigestPage() {
  const router = useRouter();
  const [digest, setDigest] = useState<Digest | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<"not_found" | "forbidden" | "unauthenticated" | null>(null);

  useEffect(() => {
    fetch("/api/v1/digest")
      .then(async (res) => {
        if (res.status === 401) { setError("unauthenticated"); return; }
        if (res.status === 403) { setError("forbidden"); return; }
        const json = await res.json();
        if (json.error?.code === "NOT_FOUND") { setError("not_found"); return; }
        if (!json.data) { setError("not_found"); return; }
        setDigest(json.data as Digest);
      })
      .catch(() => setError("not_found"))
      .finally(() => setLoading(false));
  }, []);

  // ── Loading ──
  if (loading) {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-2xl mx-auto px-5 pt-8 animate-pulse space-y-4">
          <div className="h-6 w-48 rounded bg-[var(--muted)]" />
          <div className="h-4 w-full rounded bg-[var(--muted)]" />
          <div className="h-4 w-3/4 rounded bg-[var(--muted)]" />
          {Array.from({ length: 3 }).map((_, i) => (
            <div key={i} className="p-5 rounded-2xl border border-[var(--border)] bg-[var(--surface)] space-y-2">
              <div className="h-4 w-2/3 rounded bg-[var(--muted)]" />
              <div className="h-3 w-full rounded bg-[var(--muted)]" />
              <div className="h-3 w-5/6 rounded bg-[var(--muted)]" />
            </div>
          ))}
        </div>
      </div>
    );
  }

  // ── Not authenticated ──
  if (error === "unauthenticated") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-24 text-center">
          <Lock size={40} className="mx-auto mb-4 text-[var(--text-secondary)]" />
          <h1 className="font-display text-xl font-semibold text-[var(--text-primary)] mb-2">
            Sign in to access digests
          </h1>
          <button
            onClick={() => router.push("/")}
            className="mt-4 px-5 py-3 rounded-xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
          >
            Sign in
          </button>
        </div>
      </div>
    );
  }

  // ── Not premium ──
  if (error === "forbidden") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-16 text-center">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-[var(--primary)]/10 mb-5">
            <Sparkles size={32} className="text-[var(--primary)]" />
          </div>
          <h1 className="font-display text-2xl font-bold text-[var(--text-primary)] mb-3">
            Premium feature
          </h1>
          <p className="text-sm text-[var(--text-secondary)] mb-8 max-w-sm mx-auto">
            The AI Daily Digest is available exclusively to Nexus Premium members. Get a curated summary of the top stories every morning, in your language.
          </p>
          <Link
            href="/premium"
            className="inline-flex items-center gap-2 px-6 py-3 rounded-2xl bg-[var(--primary)] text-white text-sm font-semibold hover:opacity-90 transition-opacity"
          >
            Upgrade to Premium
            <ArrowRight size={15} />
          </Link>
          <p className="text-xs text-[var(--text-secondary)] mt-4">Starting at $4.99/month</p>
        </div>
      </div>
    );
  }

  // ── No digest today ──
  if (error === "not_found") {
    return (
      <div className="min-h-screen bg-[var(--background)]">
        <Navbar />
        <div className="max-w-lg mx-auto px-5 pt-24 text-center">
          <Sparkles size={40} className="mx-auto mb-4 text-[var(--muted)]" />
          <h1 className="font-display text-xl font-semibold text-[var(--text-primary)] mb-2">
            Digest coming soon
          </h1>
          <p className="text-sm text-[var(--text-secondary)]">
            Today&apos;s digest hasn&apos;t been generated yet. Check back later.
          </p>
          <Link
            href="/feed"
            className="mt-6 inline-block text-sm text-[var(--primary)] hover:underline"
          >
            Browse today&apos;s news →
          </Link>
        </div>
      </div>
    );
  }

  if (!digest) return null;

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-2xl mx-auto px-5 pb-24 pt-6">
        {/* Header */}
        <div className="flex items-center gap-2 mb-1">
          <Sparkles size={16} className="text-[var(--primary)]" />
          <span className="text-xs font-bold uppercase tracking-wide text-[var(--primary)]">
            AI Daily Digest
          </span>
        </div>
        <h1 className="font-display text-2xl font-bold text-[var(--text-primary)] mb-1">
          {formatDigestDate(digest.digest_date)}
        </h1>
        <p className="text-xs text-[var(--text-secondary)] mb-6">
          {digest.article_count} stories · Generated at{" "}
          {new Date(digest.generated_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
        </p>

        {/* Introduction */}
        <div className="p-5 rounded-2xl border border-[var(--primary)]/20 bg-[var(--primary)]/5 mb-6">
          <p className="text-sm text-[var(--text-primary)] leading-relaxed">{digest.introduction}</p>
        </div>

        {/* Stories */}
        <div className="flex flex-col gap-4">
          {digest.stories.map((story, i) => (
            <div
              key={story.articleId || i}
              className="p-5 rounded-2xl border border-[var(--border)] bg-[var(--surface)] hover:border-[var(--primary)]/30 transition-colors"
            >
              {/* Category badge */}
              <span className="text-[10px] font-bold uppercase tracking-wider text-[var(--accent)] mb-2 block">
                {story.category}
              </span>

              {/* Title */}
              <h2 className="font-display text-base font-semibold text-[var(--text-primary)] mb-2 leading-snug">
                {story.articleId ? (
                  <Link
                    href={`/article/${story.articleId}`}
                    className="hover:text-[var(--primary)] transition-colors"
                  >
                    {story.title}
                  </Link>
                ) : (
                  story.title
                )}
              </h2>

              {/* Summary */}
              <p className="text-sm text-[var(--text-secondary)] leading-relaxed mb-3">
                {story.summary}
              </p>

              {/* Read original */}
              <a
                href={story.url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 text-xs text-[var(--primary)] hover:underline"
              >
                Read original
                <ExternalLink size={11} />
              </a>
            </div>
          ))}
        </div>

        {/* Footer */}
        <p className="text-center text-xs text-[var(--text-secondary)] mt-8">
          This digest was generated by Nexus AI and is provided for informational purposes only.
        </p>
      </main>
    </div>
  );
}
