import { getTrendingArticles } from "@/lib/db/articles";
import { ArticleCard } from "@/components/feed/article-card";

export async function TrendingFeed() {
  let articles;
  try {
    ({ articles } = await getTrendingArticles({ limit: 10 }));
  } catch (err) {
    console.error("[TrendingFeed] Error fetching articles:", err);
    return (
      <div className="p-5 text-center text-[var(--text-secondary)] border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
        <p className="text-sm">Could not load articles. Please try again later.</p>
      </div>
    );
  }

  if (articles.length === 0) {
    return (
      <div className="p-5 text-center text-[var(--text-secondary)] border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
        <p className="text-sm">No articles yet — the news feed is being populated.</p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      {articles.map((article) => (
        <ArticleCard
          key={article.id}
          title={article.title}
          source={article.sourceId || "News"}
          time={new Date(article.publishedAt).toLocaleDateString("en-US", {
            month: "short",
            day: "numeric",
          })}
          category={article.category}
        />
      ))}
    </div>
  );
}
