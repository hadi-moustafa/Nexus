import { Suspense } from "react";
import { Navbar } from "@/components/layout/navbar";
import { BreakingNewsBanner } from "@/components/feed/breaking-news-banner";
import { InteractiveMap } from "@/components/map/interactive-map";
import { TrendingFeed } from "@/components/feed/trending-feed";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen bg-[var(--background)] selection:bg-[var(--primary)] selection:text-white">
      <Navbar />

      <main className="flex-1 max-w-2xl mx-auto w-full px-5 pb-24 h-full">
        <BreakingNewsBanner />
        <InteractiveMap />

        <section className="my-10">
          <div className="flex items-center justify-between mb-6 px-1">
            <h2 className="text-[22px] font-display font-semibold text-[var(--text-primary)]">Trending Now</h2>
            <button className="text-[var(--primary)] font-semibold text-sm hover:underline hover:opacity-80 transition-opacity">
               See all
            </button>
          </div>

          <Suspense fallback={
            <div className="flex flex-col gap-4">
              <ArticleSkeleton />
              <ArticleSkeleton />
              <ArticleSkeleton />
            </div>
          }>
            <TrendingFeed />
          </Suspense>
        </section>
      </main>
    </div>
  );
}
