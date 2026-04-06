import { type NextRequest } from "next/server";
import { getArticleById } from "@/lib/db/articles";

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const article = await getArticleById(id);

    if (!article) {
      return Response.json(
        { error: { code: "NOT_FOUND", message: "Article not found" } },
        { status: 404 }
      );
    }

    return Response.json({ data: article });
  } catch (err) {
    console.error("[GET /api/v1/articles/[id]]", err);
    return Response.json(
      { error: { code: "INTERNAL_ERROR", message: "Failed to fetch article" } },
      { status: 500 }
    );
  }
}
