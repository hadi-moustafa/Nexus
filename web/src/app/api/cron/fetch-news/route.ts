import { type NextRequest } from "next/server";
import { fetchAndIngestAll } from "@/lib/gnews";

/**
 * GET /api/cron/fetch-news
 *
 * Called on a schedule (see vercel.json) to ingest fresh articles from GNews.
 * Protected by a shared secret in the x-cron-secret header — never call this
 * from the browser. Set CRON_SECRET in your environment to a random string
 * (e.g. `openssl rand -hex 32`).
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
    const result = await fetchAndIngestAll();

    console.log(
      `[cron/fetch-news] Inserted ${result.totalInserted} articles across ${result.categoriesProcessed} categories.`,
      result.errors.length > 0 ? `Errors: ${result.errors.join("; ")}` : ""
    );

    return Response.json({ data: result });
  } catch (err) {
    console.error("[cron/fetch-news]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "News ingestion failed" } },
      { status: 500 }
    );
  }
}
