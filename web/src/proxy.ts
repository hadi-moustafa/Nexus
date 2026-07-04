import { type NextRequest, NextResponse } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

/**
 * CORS headers for /api/* routes.
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

/** Replace the dev-server bind address with a real browser-navigable hostname. */
function safeUrl(request: NextRequest, path: string): URL {
  const base = request.url.replace("//0.0.0.0:", "//localhost:");
  return new URL(path, base);
}

// Pages that do not require a session.
// /payment-callback is public because the phone's browser has no session cookie
// after returning from Stripe — it just needs to fire the deep link.
const PUBLIC_PATHS = ["/login", "/payment-callback"];

function isPublic(pathname: string) {
  return PUBLIC_PATHS.some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );
}

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 1. CORS preflight — respond before any other logic
  if (request.method === "OPTIONS" && pathname.startsWith("/api/")) {
    return new NextResponse(null, {
      status: 204,
      headers: getCorsHeaders(request),
    });
  }

  // 2. API routes use Bearer token auth — skip cookie session refresh
  if (pathname.startsWith("/api/")) {
    return NextResponse.next();
  }

  // 3. Refresh the Supabase session cookie on every page request.
  //    updateSession calls supabase.auth.getUser() once and returns both the
  //    response (with refreshed cookies) and the user — no second round-trip.
  const { response, user } = await updateSession(request);

  // 4. Prevent bfcache from storing any page.
  //    Without no-store, pressing Back after logout restores a frozen
  //    in-memory snapshot without hitting the server, bypassing auth entirely.
  response.headers.set("Cache-Control", "no-store, no-cache, must-revalidate");
  response.headers.set("Pragma", "no-cache");

  // Authenticated user hitting /login → send to home
  if (user && pathname === "/login") {
    return NextResponse.redirect(safeUrl(request, "/"));
  }

  // Unauthenticated user on any non-public page → send to login
  if (!user && !isPublic(pathname)) {
    const loginUrl = safeUrl(request, "/login");
    loginUrl.searchParams.set("next", pathname);
    return NextResponse.redirect(loginUrl);
  }

  return response;
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
