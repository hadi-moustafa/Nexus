import { GoogleGenerativeAI } from "@google/generative-ai";

export interface DigestStory {
  title: string;
  summary: string;
  category: string;
  url: string;
  articleId: string;
}

export interface GeneratedDigest {
  introduction: string;
  stories: DigestStory[];
}

function getModel() {
  const key = process.env.GEMINI_API_KEY;
  if (!key) throw new Error("GEMINI_API_KEY env var is not set");
  return new GoogleGenerativeAI(key).getGenerativeModel({ model: "gemini-1.5-flash" });
}

/**
 * Generates a daily news digest from a list of top articles.
 * Returns a structured object with an intro paragraph and per-story summaries.
 */
export async function generateDigest(
  articles: Array<{ id: string; title: string; description: string | null; url: string; category: string }>,
  language: "en" | "ar" | "fr" = "en"
): Promise<GeneratedDigest> {
  const langLabel = language === "ar" ? "Arabic" : language === "fr" ? "French" : "English";

  const articleList = articles
    .slice(0, 10)
    .map((a, i) => `${i + 1}. [${a.category.toUpperCase()}] ${a.title}\n   ${a.description ?? ""}`)
    .join("\n\n");

  const prompt = `You are a news editor. Write a concise daily digest in ${langLabel} for the following top stories.

ARTICLES:
${articleList}

Respond with valid JSON matching this schema exactly:
{
  "introduction": "<2-3 sentence overview of today's news landscape>",
  "stories": [
    {
      "title": "<original article title>",
      "summary": "<2-3 sentence neutral summary>",
      "category": "<category>",
      "url": "<original url>",
      "articleId": "<article id>"
    }
  ]
}

Rules:
- Keep summaries factual and neutral (no opinion).
- Do not add articles not in the list.
- Respond ONLY with the JSON object, no markdown fences.`;

  const model = getModel();
  const result = await model.generateContent(prompt);
  const text = result.response.text().trim();

  // Strip markdown code fences if Gemini adds them anyway
  const cleaned = text.replace(/^```(?:json)?\n?/, "").replace(/\n?```$/, "");

  const parsed = JSON.parse(cleaned) as GeneratedDigest;

  // Re-attach articleId from our list (Gemini may hallucinate them)
  parsed.stories = parsed.stories.map((s, i) => ({
    ...s,
    articleId: articles[i]?.id ?? "",
    url: articles[i]?.url ?? s.url,
  }));

  return parsed;
}
