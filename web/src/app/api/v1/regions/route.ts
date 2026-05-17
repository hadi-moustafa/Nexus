import { type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";

// Maps country_code prefixes / values to display regions.
// Articles are stored with ISO 3166-1 alpha-2 country codes.
const REGION_MAP: Record<string, { name: string; countries: string[] }> = {
  europe: {
    name: "Europe",
    countries: ["GB", "FR", "DE", "IT", "ES", "NL", "BE", "SE", "NO", "DK",
                "FI", "PL", "PT", "GR", "AT", "CH", "CZ", "HU", "RO", "UA",
                "EU"],
  },
  asia: {
    name: "Asia",
    countries: ["CN", "JP", "KR", "IN", "ID", "TH", "VN", "PH", "MY", "SG",
                "PK", "BD", "LK", "MM", "KH", "LA", "MN", "KZ", "UZ"],
  },
  "middle-east": {
    name: "Middle East",
    countries: ["LB", "SA", "AE", "TR", "IL", "IQ", "IR", "JO", "SY", "YE",
                "KW", "QA", "BH", "OM", "EG"],
  },
  americas: {
    name: "Americas",
    countries: ["US", "CA", "MX", "BR", "AR", "CO", "CL", "PE", "VE", "EC",
                "BO", "UY", "PY", "CU"],
  },
  africa: {
    name: "Africa",
    countries: ["ZA", "NG", "KE", "GH", "EG", "ET", "TZ", "UG", "DZ", "MA",
                "TN", "LY", "SD", "CM", "CI"],
  },
  oceania: {
    name: "Oceania",
    countries: ["AU", "NZ", "FJ", "PG", "WS"],
  },
};

/**
 * GET /api/v1/regions
 *
 * Returns article counts per world region (last 7 days).
 * Used by the mobile map to show hotspot numbers.
 *
 * Response: { data: [{ slug, name, articleCount }] }
 */
export async function GET(_request: NextRequest) {
  try {
    const supabase = createServiceClient();
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

    // Fetch country-level article counts from the last 7 days
    const { data, error } = await supabase
      .from("articles")
      .select("country_code")
      .gte("published_at", since);

    if (error) throw error;

    // Tally counts per region
    const regionCounts: Record<string, number> = {};
    for (const row of data ?? []) {
      const code = (row.country_code as string | null)?.toUpperCase();
      if (!code) continue;
      for (const [slug, region] of Object.entries(REGION_MAP)) {
        if (region.countries.includes(code)) {
          regionCounts[slug] = (regionCounts[slug] ?? 0) + 1;
          break;
        }
      }
    }

    const result = Object.entries(REGION_MAP).map(([slug, { name }]) => ({
      slug,
      name,
      articleCount: regionCounts[slug] ?? 0,
    }));

    return Response.json(
      { data: result },
      {
        headers: {
          "Cache-Control": "public, s-maxage=300, stale-while-revalidate=900",
        },
      }
    );
  } catch (err) {
    console.error("[GET /api/v1/regions]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch region data" } },
      { status: 500 }
    );
  }
}
