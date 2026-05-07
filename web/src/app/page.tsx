import { Suspense } from "react";
import Link from "next/link";
import { Trophy, Sparkles, BarChart2, PuzzleIcon } from "lucide-react";
import { Navbar } from "@/components/layout/navbar";
import { BreakingNewsBanner } from "@/components/feed/breaking-news-banner";
import { TrendingFeed } from "@/components/feed/trending-feed";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";

const CATEGORIES = [
  { label: "🇱🇧 Lebanon",       href: "/feed?cat=lebanon"       },
  { label: "🌍 World",          href: "/feed?cat=world"         },
  { label: "💻 Tech",           href: "/feed?cat=technology"    },
  { label: "📈 Business",       href: "/feed?cat=business"      },
  { label: "⚽ Sports",         href: "/feed?cat=sports"        },
  { label: "🔬 Science",        href: "/feed?cat=science"       },
  { label: "❤️ Health",         href: "/feed?cat=health"        },
  { label: "🎬 Entertainment",  href: "/feed?cat=entertainment" },
];

const EXPLORE = [
  { href: "/quiz",        icon: Trophy,      label: "Daily Quiz",  sub: "Test your news IQ",    color: "text-amber-500" },
  { href: "/leaderboard", icon: BarChart2,   label: "Leaderboard", sub: "See top readers",       color: "text-blue-500"  },
  { href: "/digest",      icon: Sparkles,    label: "AI Digest",   sub: "Premium recap",         color: "text-violet-500"},
  { href: "/crossword",   icon: PuzzleIcon,  label: "Crossword",   sub: "Daily puzzle",          color: "text-green-500" },
];

function SidebarSkeleton() {
  return (
    <div>
      {Array.from({ length: 6 }).map((_, i) => (
        <ArticleSkeleton key={i} variant="compact" />
      ))}
    </div>
  );
}

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen bg-[var(--background)] selection:bg-[var(--primary)] selection:text-white">
      <Navbar />
      <BreakingNewsBanner />

      <main className="flex-1 w-full max-w-screen-xl mx-auto px-4 sm:px-6 lg:px-8 pt-6 pb-20 md:pb-8">

        {/* Category shortcuts */}
        <div className="flex items-center gap-2 overflow-x-auto scrollbar-none pb-1 mb-8">
          {CATEGORIES.map(({ label, href }) => (
            <Link
              key={href}
              href={href}
              className="shrink-0 px-4 py-1.5 rounded-full bg-[var(--surface)] border border-[var(--border)] text-[13px] font-medium text-[var(--text-secondary)] hover:border-[var(--primary)] hover:text-[var(--primary)] transition-all shadow-[var(--shadow-xs)]"
            >
              {label}
            </Link>
          ))}
        </div>

        {/* Two-column grid */}
        <div className="grid grid-cols-1 lg:grid-cols-[1fr_320px] xl:grid-cols-[1fr_360px] gap-8 items-start">

          {/* ── Main feed ────────────────────────────────────── */}
          <section>
            <div className="flex items-center gap-3 mb-5">
              <div className="flex items-center gap-2">
                <span className="w-1 h-5 rounded-full bg-[var(--primary)] block" />
                <h2 className="text-xl font-display font-bold text-[var(--text-primary)]">Top Stories</h2>
              </div>
              <span className="h-px flex-1 bg-[var(--border)]" />
              <Link href="/feed" className="text-sm font-semibold text-[var(--primary)] hover:underline shrink-0">
                See all →
              </Link>
            </div>

            <Suspense fallback={
              <div className="flex flex-col gap-4">
                <ArticleSkeleton variant="hero" />
                <ArticleSkeleton variant="featured" />
                <ArticleSkeleton variant="featured" />
              </div>
            }>
              <TrendingFeed layout="default" limit={8} />
            </Suspense>
          </section>

          {/* ── Sidebar ──────────────────────────────────────── */}
          <aside className="lg:sticky lg:top-20 flex flex-col gap-6">

            {/* Trending list */}
            <div className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl shadow-[var(--shadow-card)] overflow-hidden">
              <div className="flex items-center gap-2 px-4 py-3 border-b border-[var(--border)]">
                <span className="w-1 h-4 rounded-full bg-[var(--accent)] block" />
                <h3 className="text-[15px] font-display font-bold text-[var(--text-primary)]">Trending</h3>
              </div>
              <div className="px-3 py-1">
                <Suspense fallback={<SidebarSkeleton />}>
                  <TrendingFeed layout="sidebar" limit={8} />
                </Suspense>
              </div>
            </div>

            {/* Explore shortcuts */}
            <div>
              <div className="flex items-center gap-2 mb-3">
                <span className="w-1 h-4 rounded-full bg-[var(--primary)] block" />
                <h3 className="text-[15px] font-display font-bold text-[var(--text-primary)]">Explore</h3>
              </div>
              <div className="grid grid-cols-2 gap-2.5">
                {EXPLORE.map(({ href, icon: Icon, label, sub, color }) => (
                  <Link
                    key={href}
                    href={href}
                    className="group flex flex-col gap-1.5 p-3.5 rounded-xl bg-[var(--surface)] border border-[var(--border)] hover:border-[var(--primary)]/40 transition-all shadow-[var(--shadow-xs)] card-lift"
                  >
                    <Icon size={18} className={`${color} group-hover:scale-110 transition-transform`} />
                    <span className="text-[13px] font-semibold text-[var(--text-primary)]">{label}</span>
                    <span className="text-[11px] text-[var(--text-muted)]">{sub}</span>
                  </Link>
                ))}
              </div>
            </div>

          </aside>
        </div>
      </main>
    </div>
  );
}
