import { type NextRequest } from "next/server";
import { fetchAndIngestAll } from "@/lib/gnews";
import { fetchAndIngestFromGuardian } from "@/lib/guardian";
import { fetchAndIngestArabic } from "@/lib/arabic";

/**
 * GET /api/cron/fetch-news
 *
 * Called on a schedule (see vercel.json) to ingest fresh articles from both
 * GNews and The Guardian. Protected by a shared secret in the x-cron-secret
 * header. Set CRON_SECRET in your environment to a random string.
 */
export async function GET(request: NextRequest) {
  const secret = request.headers.get("x-cron-secret");

  if (!process.env.CRON_SECRET || secret !== process.env.CRON_SECRET) {
    return Response.json(
      { error: { code: "UNAUTHORIZED", message: "Invalid or missing cron secret" } },
      { status: 401 }
    );
  }

  try {
    const [gnews, guardian, arabic] = await Promise.allSettled([
      fetchAndIngestAll(),
      fetchAndIngestFromGuardian(),
      fetchAndIngestArabic(),
    ]);

    const gnewsResult   = gnews.status   === "fulfilled" ? gnews.value   : null;
    const guardianResult = guardian.status === "fulfilled" ? guardian.value : null;
    const arabicResult   = arabic.status   === "fulfilled" ? arabic.value   : null;

    console.log(
      `[cron/fetch-news] GNews: ${gnewsResult?.totalInserted ?? 0}, ` +
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
    console.error("[cron/fetch-news]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "News ingestion failed" } },
      { status: 500 }
    );
  }
}
