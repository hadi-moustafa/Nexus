import { getTrendingArticles } from "@/lib/db/articles";
import { ArticleCard } from "@/components/feed/article-card";

export type FeedLayout = "default" | "sidebar" | "grid";

interface TrendingFeedProps {
  layout?: FeedLayout;
  limit?: number;
}

function EmptyState({ message }: { message: string }) {
  return (
    <div className="p-6 text-center text-[var(--text-secondary)] border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
      <p className="text-sm">{message}</p>
    </div>
  );
}

export async function TrendingFeed({ layout = "default", limit = 10 }: TrendingFeedProps) {
  let articles;
  try {
    ({ articles } = await getTrendingArticles({ limit }));
  } catch (err) {
    console.error("[TrendingFeed] Error fetching articles:", (err as Error)?.message ?? err);
    return <EmptyState message="Could not load articles. Please try again later." />;
  }

  if (articles.length === 0) {
    return <EmptyState message="No articles yet — the feed is being populated. Check back soon." />;
  }

  /* ── Sidebar: numbered compact list ─────────────────────────── */
  if (layout === "sidebar") {
    return (
      <div>
        {articles.map((article, i) => (
          <ArticleCard key={article.id} article={article} variant="compact" index={i + 1} />
        ))}
      </div>
    );
  }

  /* ── Grid: featured hero + 3-col grid ───────────────────────── */
  if (layout === "grid") {
    const [first, ...rest] = articles;
    return (
      <div className="flex flex-col gap-4">
        {first && <ArticleCard article={first} variant="featured" />}
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          {rest.map((article) => (
            <ArticleCard key={article.id} article={article} />
          ))}
        </div>
      </div>
    );
  }

  /* ── Default: hero first + featured list ─────────────────────── */
  const [hero, ...rest] = articles;
  return (
    <div className="flex flex-col gap-4">
      {hero && <ArticleCard article={hero} variant="hero" />}
      {rest.map((article) => (
        <ArticleCard key={article.id} article={article} variant="featured" />
      ))}
    </div>
  );
}
