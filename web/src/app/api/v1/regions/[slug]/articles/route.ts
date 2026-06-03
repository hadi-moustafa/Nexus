import { type NextRequest } from "next/server";
import { getArticles } from "@/lib/db/articles";

const REGION_COUNTRIES: Record<string, string[]> = {
  europe: ["GB", "FR", "DE", "IT", "ES", "NL", "BE", "SE", "NO", "DK",
           "FI", "PL", "PT", "GR", "AT", "CH", "CZ", "HU", "RO", "UA", "EU"],
  asia: ["CN", "JP", "KR", "IN", "ID", "TH", "VN", "PH", "MY", "SG",
         "PK", "BD", "LK", "MM", "KH", "LA", "MN", "KZ", "UZ"],
  "middle-east": ["LB", "SA", "AE", "TR", "IL", "IQ", "IR", "JO", "SY",
                  "YE", "KW", "QA", "BH", "OM", "EG"],
  americas: ["US", "CA", "MX", "BR", "AR", "CO", "CL", "PE", "VE", "EC",
             "BO", "UY", "PY", "CU"],
  africa: ["ZA", "NG", "KE", "GH", "EG", "ET", "TZ", "UG", "DZ", "MA",
           "TN", "LY", "SD", "CM", "CI"],
  oceania: ["AU", "NZ", "FJ", "PG", "WS"],
};

/**
 * GET /api/v1/regions/[slug]/articles
 *
 * Returns paginated articles for a world region (by country_code).
 * Used by the mobile world map country panel.
 */
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ slug: string }> }
) {
  const { slug } = await params;
  const countryCodes = REGION_COUNTRIES[slug];

  if (!countryCodes) {
    return Response.json(
      { error: { code: "NOT_FOUND", message: `Unknown region: ${slug}` } },
      { status: 404 }
    );
  }

  try {
    const { searchParams } = request.nextUrl;
    const limit = Math.min(Number(searchParams.get("limit") ?? "20"), 50);
    const cursor = searchParams.get("cursor") ?? undefined;

    const { articles, nextCursor } = await getArticles({ limit, cursor, countryCodes });

    return Response.json(
      { data: articles, meta: { nextCursor } },
      { headers: { "Cache-Control": "public, s-maxage=120, stale-while-revalidate=600" } }
    );
  } catch (err) {
    console.error(`[GET /api/v1/regions/${slug}/articles]`, err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch region articles" } },
      { status: 500 }
    );
  }
}
