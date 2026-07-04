import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { createClient } from "@/lib/supabase/server";
import { Navbar } from "@/components/layout/navbar";
import { BreakingNewsBanner } from "@/components/feed/breaking-news-banner";
import { TrendingFeed } from "@/components/feed/trending-feed";
import Link from "next/link";

export default async function RootPage() {
  const cookieStore = await cookies();
  const supabase = createClient(cookieStore);
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />
      <BreakingNewsBanner />

      <main className="max-w-screen-xl mx-auto px-4 sm:px-6 lg:px-8 py-6 pb-16">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

          {/* ── Main feed ─────────────────────────────────────────── */}
          <section className="lg:col-span-2">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-xl font-bold text-[var(--text-primary)]">Top Stories</h2>
              <Link
                href="/feed"
                className="text-sm font-semibold text-[var(--primary)] hover:underline"
              >
                See all →
              </Link>
            </div>
            <TrendingFeed layout="default" limit={8} />
          </section>

          {/* ── Sidebar ───────────────────────────────────────────── */}
          <aside className="lg:col-span-1">
            <h2 className="text-xl font-bold text-[var(--text-primary)] mb-5">Trending</h2>
            <div className="sticky top-20">
              <TrendingFeed layout="sidebar" limit={6} />
            </div>
          </aside>

        </div>
      </main>
    </div>
  );
}
