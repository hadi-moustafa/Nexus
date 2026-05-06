import { type NextRequest, NextResponse } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

/**
 * CORS headers for /api/* routes.
 * Allows any localhost origin (Flutter Web dev, web dashboard dev).
 * In production, restrict this to your deployed app domains.
 */
function getCorsHeaders(request: NextRequest): Record<string, string> {
  const origin = request.headers.get("origin") ?? "";
  const isLocalhost =
    origin.startsWith("http://localhost") ||
    origin.startsWith("http://127.0.0.1");

  if (!isLocalhost) return {};

  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
    "Access-Control-Allow-Headers":
      "Content-Type, Authorization, x-cron-secret",
    "Access-Control-Max-Age": "86400",
  };
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 1. Handle CORS preflight — must respond before any other logic
  if (request.method === "OPTIONS" && pathname.startsWith("/api/")) {
    return new NextResponse(null, {
      status: 204,
      headers: getCorsHeaders(request),
    });
  }

  // 2. Always refresh the Supabase session cookie (keeps it from expiring)
  const response = await updateSession(request);

  // 3. Attach CORS headers to every API response so the browser allows it
  if (pathname.startsWith("/api/")) {
    const cors = getCorsHeaders(request);
    for (const [key, value] of Object.entries(cors)) {
      response.headers.set(key, value);
    }
  }

  // 4. If authenticated user hits /login, redirect home
  if (pathname === "/login") {
    const { createServerClient } = await import("@supabase/ssr");
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY!,
      {
        cookies: {
          getAll: () => request.cookies.getAll(),
          setAll: () => {},
        },
      }
    );
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (user) {
      return NextResponse.redirect(new URL("/feed", request.url));
    }
  }

  return response;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
