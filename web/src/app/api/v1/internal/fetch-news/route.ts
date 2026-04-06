import { type NextRequest } from "next/server";
import { requireAuth } from "@/lib/auth";
import { fetchAndIngestAll } from "@/lib/gnews";

/**
 * POST /api/v1/internal/fetch-news
 *
 * Manual trigger for news ingestion — for use from the admin dashboard.
 * Requires an authenticated session (full admin role check added in Phase 7).
 *
 * Example: fetch('/api/v1/internal/fetch-news', { method: 'POST' })
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth; // 401

  try {
    const result = await fetchAndIngestAll();

    console.log(
      `[internal/fetch-news] Triggered by user ${auth.userId}. ` +
        `Inserted ${result.totalInserted} articles.`,
      result.errors.length > 0 ? `Errors: ${result.errors.join("; ")}` : ""
    );

    return Response.json({ data: result });
  } catch (err) {
    console.error("[internal/fetch-news]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "News ingestion failed" } },
      { status: 500 }
    );
  }
}
