import { type NextRequest } from "next/server";
import { requireAuth } from "@/lib/auth";
import { fetchAndIngestAll } from "@/lib/gnews";
import { fetchAndIngestFromGuardian } from "@/lib/guardian";
import { fetchAndIngestArabic } from "@/lib/arabic";

/**
 * POST /api/v1/internal/fetch-news
 *
 * Manual trigger for news ingestion from both GNews and The Guardian.
 * For use from the admin dashboard. Requires an authenticated session.
 */
export async function POST(request: NextRequest) {
  const auth = await requireAuth(request);
  if (auth instanceof Response) return auth; // 401

  try {
    const [gnews, guardian, arabic] = await Promise.allSettled([
      fetchAndIngestAll(),
      fetchAndIngestFromGuardian(),
      fetchAndIngestArabic(),
    ]);

    const gnewsResult    = gnews.status    === "fulfilled" ? gnews.value    : null;
    const guardianResult = guardian.status === "fulfilled" ? guardian.value : null;
    const arabicResult   = arabic.status   === "fulfilled" ? arabic.value   : null;

    console.log(
      `[internal/fetch-news] Triggered by user ${auth.userId}. ` +
      `GNews: ${gnewsResult?.totalInserted ?? 0}, ` +
      `Guardian: ${guardianResult?.totalInserted ?? 0}, ` +
      `Arabic: ${arabicResult?.totalInserted ?? 0} articles.`
    );

    return Response.json({
      data: {
        gnews: gnewsResult,
        guardian: guardianResult,
        arabic: arabicResult,
        gnewsError:   gnews.status   === "rejected" ? String(gnews.reason)   : null,
        guardianError: guardian.status === "rejected" ? String(guardian.reason) : null,
        arabicError:  arabic.status   === "rejected" ? String(arabic.reason)  : null,
      },
    });
  } catch (err) {
    console.error("[internal/fetch-news]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "News ingestion failed" } },
      { status: 500 }
    );
  }
}
