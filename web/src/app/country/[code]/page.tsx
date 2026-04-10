import { Suspense } from "react";
import { notFound } from "next/navigation";
import { ArrowLeft, MapPin } from "lucide-react";
import Link from "next/link";
import { getArticles } from "@/lib/db/articles";
import { Navbar } from "@/components/layout/navbar";
import { ArticleCard } from "@/components/feed/article-card";
import { ArticleSkeleton } from "@/components/feed/article-skeleton";
import type { Metadata } from "next";

// Static country name map — bundled at build time, no API call needed.
const COUNTRY_NAMES: Record<string, string> = {
  us: "United States", gb: "United Kingdom", fr: "France", de: "Germany",
  lb: "Lebanon", ae: "UAE", sa: "Saudi Arabia", eg: "Egypt", jo: "Jordan",
  iq: "Iraq", sy: "Syria", tr: "Turkey", ir: "Iran", il: "Israel",
  cn: "China", jp: "Japan", in: "India", br: "Brazil", ru: "Russia",
  ca: "Canada", au: "Australia", za: "South Africa", ng: "Nigeria",
  ke: "Kenya", mx: "Mexico", ar: "Argentina", it: "Italy", es: "Spain",
  kr: "South Korea", pk: "Pakistan", bd: "Bangladesh",
};

interface Props {
  params: Promise<{ code: string }>;
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { code } = await params;
  const name = COUNTRY_NAMES[code.toLowerCase()] ?? code.toUpperCase();
  return {
    title: `${name} News | Nexus`,
    description: `Latest news from ${name} on Nexus.`,
  };
}

async function CountryFeed({ code }: { code: string }) {
  const { articles } = await getArticles({ countryCode: code, limit: 20 });

  if (articles.length === 0) {
    return (
      <div className="p-6 text-center text-[var(--text-secondary)] border border-[var(--border)] rounded-2xl bg-[var(--surface)]">
        <p className="text-sm">No articles found for this country yet.</p>
        <p className="text-xs mt-2 text-[var(--text-secondary)]/70">
          News is fetched and cached periodically. Check back soon.
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {articles.map((article) => (
        <ArticleCard key={article.id} article={article} />
      ))}
    </div>
  );
}

export default async function CountryPage({ params }: Props) {
  const { code } = await params;
  const normalised = code.toLowerCase();
  const countryName = COUNTRY_NAMES[normalised];

  // Only serve known country codes — prevents arbitrary DB queries
  if (!countryName) notFound();

  const isLebanon = normalised === "lb";

  return (
    <div className="min-h-screen bg-[var(--background)]">
      <Navbar />

      <main className="max-w-2xl mx-auto px-5 pb-24">
        {/* Back */}
        <div className="py-4">
          <Link
            href="/"
            className="inline-flex items-center gap-1.5 text-sm text-[var(--text-secondary)] hover:text-[var(--text-primary)] transition-colors"
          >
            <ArrowLeft size={16} />
            Back to map
          </Link>
        </div>

        {/* Header */}
        <div className={`mb-6 p-5 rounded-2xl border ${isLebanon ? "border-[var(--primary)]/40 bg-[var(--primary)]/5" : "border-[var(--border)] bg-[var(--surface)]"}`}>
          <div className="flex items-center gap-3">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${isLebanon ? "bg-[var(--primary)]" : "bg-[var(--muted)]"}`}>
              <MapPin size={20} className={isLebanon ? "text-white" : "text-[var(--text-secondary)]"} />
            </div>
            <div>
              <h1 className="font-display text-2xl font-semibold text-[var(--text-primary)]">
                {countryName}
              </h1>
              {isLebanon && (
                <p className="text-xs text-[var(--primary)] font-medium mt-0.5">Lebanese Spotlight</p>
              )}
            </div>
          </div>
        </div>

        {/* Articles */}
        <Suspense fallback={
          <div className="flex flex-col gap-3">
            {Array.from({ length: 5 }).map((_, i) => <ArticleSkeleton key={i} />)}
          </div>
        }>
          <CountryFeed code={normalised} />
        </Suspense>
      </main>
    </div>
  );
}
