"use client";

import { useState, useEffect, useCallback, useRef, Suspense } from "react";
import { useSearchParams, useRouter } from "next/navigation";
import { Search, X } from "lucide-react";
import { Navbar } from "@/components/layout/navbar";
import { ArticleCard } from "@/components/feed/article-card";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";
import type { Article } from "@/types";

const CATEGORIES = [
  { label: "All",          value: "" },
  { label: "World",        value: "world" },
  { label: "Technology",   value: "technology" },
  { label: "Business",     value: "business" },
  { label: "Sports",       value: "sports" },
  { label: "Health",       value: "health" },
];

function SearchContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const initialQ = searchParams.get("q") ?? "";

  const [inputValue, setInputValue] = useState(initialQ);
  const [query, setQuery] = useState(initialQ);
  const [category, setCategory] = useState("");
  const [articles, setArticles] = useState<Article[]>([]);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [hasSearched, setHasSearched] = useState(!!initialQ);
  const sentinelRef = useRef<HTMLDivElement>(null);

  const doSearch = useCallback(async (q: string, cat: string, cursor?: string) => {
    if (!q.trim()) return;
    const params = new URLSearchParams({ q, limit: "20" });
    if (cat) params.set("category", cat);
    if (cursor) params.set("cursor", cursor);
    const res = await fetch(`/api/v1/search?${params}`);
    if (!res.ok) throw new Error("Search failed");
    return res.json() as Promise<{ data: Article[]; meta: { nextCursor: string | null } }>;
  }, []);

  // Trigger search when query or category changes
  useEffect(() => {
    if (!query) return;
    let cancelled = false;
    setLoading(true);
    setHasSearched(true);
    setArticles([]);
    setNextCursor(null);

    doSearch(query, category)
      .then((result) => {
        if (cancelled || !result) return;
        setArticles(result.data);
        setNextCursor(result.meta.nextCursor);
      })
      .catch(console.error)
      .finally(() => { if (!cancelled) setLoading(false); });

    return () => { cancelled = true; };
  }, [query, category, doSearch]);

  // Infinite scroll
  useEffect(() => {
    if (!nextCursor) return;
    const sentinel = sentinelRef.current;
    if (!sentinel) return;

    const observer = new IntersectionObserver(
      (entries) => {
        if (!entries[0].isIntersecting || loadingMore || !nextCursor) return;
        setLoadingMore(true);
        doSearch(query, category, nextCursor)
          .then((result) => {
            if (!result) return;
            setArticles((prev) => [...prev, ...result.data]);
            setNextCursor(result.meta.nextCursor);
          })
          .catch(console.error)
          .finally(() => setLoadingMore(false));
      },
      { rootMargin: "200px" }
    );
    observer.observe(sentinel);
    return () => observer.disconnect();
  }, [nextCursor, loadingMore, query, category, doSearch]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = inputValue.trim();
    if (!trimmed) return;
    router.replace(`/search?q=${encodeURIComponent(trimmed)}`);
    setQuery(trimmed);
  };

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-2xl mx-auto px-5 pb-24">
        {/* Search bar */}
        <div className="sticky top-[72px] z-40 bg-[var(--background)] pt-4 pb-3">
          <form onSubmit={handleSubmit} className="relative">
            <Search
              size={18}
              className="absolute left-4 top-1/2 -translate-y-1/2 text-[var(--text-secondary)] pointer-events-none"
            />
            <input
              type="search"
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              placeholder="Search articles…"
              autoFocus
              className="w-full pl-11 pr-10 py-3 rounded-xl bg-[var(--surface)] border border-[var(--border)] text-[var(--text-primary)] text-sm placeholder:text-[var(--text-secondary)] focus:outline-none focus:border-[var(--primary)] transition-colors"
            />
            {inputValue && (
              <button
                type="button"
                onClick={() => { setInputValue(""); setQuery(""); setHasSearched(false); }}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
              >
                <X size={16} />
              </button>
            )}
          </form>

          {/* Category filter chips */}
          {hasSearched && (
            <div className="flex gap-1.5 mt-3 overflow-x-auto scrollbar-none">
              {CATEGORIES.map((cat) => (
                <button
                  key={cat.value}
                  onClick={() => setCategory(cat.value)}
                  className={`shrink-0 px-3 py-1 rounded-full text-xs font-medium transition-all ${
                    category === cat.value
                      ? "bg-[var(--primary)] text-white"
                      : "bg-[var(--muted)] text-[var(--text-secondary)] hover:text-[var(--text-primary)]"
                  }`}
                >
                  {cat.label}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Empty state */}
        {!hasSearched && (
          <div className="flex flex-col items-center justify-center py-24 text-center">
            <Search size={48} className="text-[var(--muted)] mb-4" />
            <p className="text-[var(--text-secondary)] text-sm">
              Search for any topic, story, or keyword
            </p>
          </div>
        )}

        {/* Loading */}
        {loading && (
          <div className="flex flex-col gap-3 mt-2">
            {Array.from({ length: 4 }).map((_, i) => <ArticleSkeleton key={i} />)}
          </div>
        )}

        {/* No results */}
        {!loading && hasSearched && articles.length === 0 && (
          <div className="py-16 text-center text-[var(--text-secondary)]">
            <p className="text-sm">No results for <strong>&ldquo;{query}&rdquo;</strong></p>
            <p className="text-xs mt-2">Try a different keyword or remove the category filter.</p>
          </div>
        )}

        {/* Results */}
        {!loading && articles.length > 0 && (
          <>
            <p className="text-xs text-[var(--text-secondary)] mb-4">
              Results for <strong>&ldquo;{query}&rdquo;</strong>
            </p>
            <div className="flex flex-col gap-3">
              {articles.map((a) => <ArticleCard key={a.id} article={a} />)}
            </div>
          </>
        )}

        <div ref={sentinelRef} className="h-1" />
        {loadingMore && (
          <div className="flex flex-col gap-3 mt-3">
            <ArticleSkeleton />
          </div>
        )}
      </main>
    </div>
  );
}

export default function SearchPage() {
  return (
    <Suspense>
      <SearchContent />
    </Suspense>
  );
}
