# Nexus — Refactoring & Architecture Plan

## Executive Summary

The current codebase has a web app that talks directly to Supabase, a mobile app with 100% hardcoded mock data, and a Deno edge function handling news ingestion. The goal is a clean monorepo where:

- The **Next.js app becomes the single backend** for both clients
- **Supabase is used only for**: PostgreSQL database + Google OAuth
- The **mobile app** treats Next.js API routes as its sole data source (never touches Supabase directly)
- The **web app** becomes an admin/editorial dashboard backed by the same API layer
- **All business logic lives locally** in TypeScript — no Supabase Edge Functions

---

## 1. Target Folder Structure

```
Nexus/
├── web/                          # Next.js 16 — management dashboard + API server
│   └── src/
│       ├── app/
│       │   ├── layout.tsx
│       │   ├── page.tsx          # Redirects to /dashboard
│       │   ├── (auth)/           # Route group — auth pages
│       │   │   ├── login/page.tsx
│       │   │   └── callback/route.ts   # Supabase OAuth callback
│       │   ├── (dashboard)/      # Route group — protected editorial dashboard
│       │   │   ├── layout.tsx    # Dashboard shell with sidebar
│       │   │   ├── dashboard/page.tsx
│       │   │   ├── articles/page.tsx
│       │   │   ├── articles/[id]/page.tsx
│       │   │   ├── sources/page.tsx
│       │   │   └── users/page.tsx
│       │   └── api/
│       │       ├── v1/           # All REST API routes (consumed by web SSR + mobile)
│       │       │   ├── trending/route.ts
│       │       │   ├── articles/route.ts
│       │       │   ├── articles/[id]/route.ts
│       │       │   ├── feed/route.ts             # Personalised, auth-gated
│       │       │   ├── search/route.ts
│       │       │   ├── regions/route.ts
│       │       │   ├── regions/[slug]/articles/route.ts
│       │       │   ├── auth/session/route.ts
│       │       │   ├── auth/signout/route.ts
│       │       │   ├── user/preferences/route.ts
│       │       │   ├── user/stats/route.ts
│       │       │   ├── user/bookmarks/route.ts
│       │       │   ├── quiz/daily/route.ts
│       │       │   ├── quiz/submit/route.ts
│       │       │   └── internal/fetch-news/route.ts  # Admin manual trigger
│       │       └── cron/
│       │           └── fetch-news/route.ts       # Called by scheduler, x-cron-secret protected
│       ├── components/
│       │   ├── layout/
│       │   │   ├── navbar.tsx               # Keep existing
│       │   │   ├── dashboard-sidebar.tsx    # New
│       │   │   └── dashboard-header.tsx     # New
│       │   ├── feed/                        # Keep all existing components
│       │   │   ├── article-card.tsx
│       │   │   ├── article-skeleton.tsx
│       │   │   ├── breaking-news-banner.tsx
│       │   │   └── trending-feed.tsx        # Refactored to call API, not Supabase directly
│       │   ├── map/interactive-map.tsx
│       │   └── dashboard/                   # New: admin-only components
│       │       ├── article-table.tsx
│       │       ├── stats-card.tsx
│       │       └── source-badge.tsx
│       ├── lib/                             # Pure server-side utilities
│       │   ├── supabase/
│       │   │   ├── server.ts               # Moved from utils/supabase/server.ts
│       │   │   ├── client.ts               # Moved from utils/supabase/client.ts
│       │   │   └── middleware.ts           # Moved from utils/supabase/middleware.ts
│       │   ├── db/
│       │   │   ├── articles.ts             # DB query functions
│       │   │   ├── users.ts
│       │   │   └── quiz.ts
│       │   ├── gnews.ts                    # GNews client (migrated from Deno edge function)
│       │   └── auth.ts                     # requireAuth() — unified for cookie + bearer
│       ├── types/
│       │   └── index.ts                    # Canonical shared TypeScript types
│       └── middleware.ts                   # Keep existing, add route protection
├── mobile/                       # Flutter — same structure, add networking layer
│   └── lib/
│       ├── main.dart
│       ├── config/
│       │   └── api_config.dart             # New: baseUrl, env switching
│       ├── services/                       # New: all HTTP calls
│       │   ├── api_client.dart             # Base HTTP client
│       │   ├── articles_service.dart
│       │   ├── auth_service.dart
│       │   ├── user_service.dart
│       │   └── quiz_service.dart
│       ├── models/                         # New: Dart models mirroring TS types
│       │   ├── article.dart
│       │   ├── user_profile.dart
│       │   ├── user_stats.dart
│       │   ├── quiz_question.dart
│       │   └── region.dart
│       ├── screens/                        # Keep all, wire up real data
│       └── widgets/                        # Keep all
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   └── functions/fetch-news/index.ts       # DEPRECATED — migrated to web/src/lib/gnews.ts
└── .env.example
```

---

## 2. API Contract

### Conventions

- Base path: `/api/v1/`
- All responses: `Content-Type: application/json`
- Auth: session cookie (web SSR) or `Authorization: Bearer <access_token>` header (mobile)
- Error shape: `{ "error": { "code": string, "message": string } }`
- Success shape: `{ "data": T, "meta"?: { nextCursor, total } }`
- Pagination: cursor-based, `?cursor=<encoded>&limit=<n>` (default 20, max 50)

### Public Endpoints

```
GET  /api/v1/trending                          ?limit&cursor
GET  /api/v1/articles                          ?category&limit&cursor
GET  /api/v1/articles/:id
GET  /api/v1/search                            ?q&category&limit&cursor
GET  /api/v1/regions
GET  /api/v1/regions/:slug/articles            ?limit&cursor
```

### Authenticated Endpoints

```
GET  /api/v1/auth/session
POST /api/v1/auth/signout

GET  /api/v1/feed                              ?limit&cursor  (personalised)

GET  /api/v1/user/preferences
PATCH /api/v1/user/preferences

GET  /api/v1/user/stats
GET  /api/v1/user/bookmarks                    ?limit&cursor
POST /api/v1/user/bookmarks                    body: { articleId }
DELETE /api/v1/user/bookmarks/:articleId

GET  /api/v1/quiz/daily
POST /api/v1/quiz/submit                       body: { sessionId, answers[] }
```

### Internal / Cron

```
GET  /api/cron/fetch-news                      header: x-cron-secret
POST /api/v1/internal/fetch-news               requires admin session
```

### Canonical Types (`web/src/types/index.ts`)

```typescript
export interface Article {
  id: string;
  title: string;
  summary: string | null;
  content: string | null;
  url: string;
  imageUrl: string | null;
  publishedAt: string;        // ISO 8601
  sourceId: string;
  category: string;
  language: string;
  region: string | null;
}

export interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  createdAt: string;
}

export interface UserPreferences {
  topics: string[];
  preferredLanguage: string;
  onboardingComplete: boolean;
}

export interface UserStats {
  totalXp: number;
  currentStreak: number;
  longestStreak: number;
  quizzesCompleted: number;
  perfectScores: number;
  articlesRead: number;
}

export interface QuizQuestion {
  id: string;
  question: string;
  options: string[];
  timeLimit: number;
}

export interface QuizSession {
  id: string;
  questions: QuizQuestion[];
  expiresAt: string;
}

export interface Region {
  slug: string;
  label: string;
  articleCount: number;
}

export interface ApiSuccess<T> {
  data: T;
  meta?: { nextCursor?: string | null; total?: number };
}

export interface ApiError {
  error: { code: ApiErrorCode; message: string };
}

export type ApiErrorCode =
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'NOT_FOUND'
  | 'VALIDATION_ERROR'
  | 'RATE_LIMITED'
  | 'INTERNAL_ERROR';
```

---

## 3. Auth Flow

### Web Dashboard (Google OAuth via Supabase, cookie session)

```
1. Visit /dashboard → middleware checks session → redirect to /login if none
2. /login renders "Sign in with Google" button
3. Button calls supabase.auth.signInWithOAuth({ provider: 'google',
     options: { redirectTo: `${origin}/api/v1/auth/callback` } })
4. Google → Supabase → /api/v1/auth/callback
5. Callback: supabase.auth.exchangeCodeForSession(code) → sets cookie
6. Redirect to /dashboard
7. Middleware refreshes session on every request via supabase.auth.getUser()
8. Sign-out: POST /api/v1/auth/signout → supabase.auth.signOut() → clear cookie
```

### Mobile (Google OAuth via Supabase, bearer token stored locally)

```
1. App launches → auth_service.getSession() with stored access_token
   → 401 or no token → show LoginScreen
2. LoginScreen: google_sign_in package → Google ID token
3. POST to Supabase Auth directly: signInWithIdToken({ provider: 'google', idToken })
   (ONLY time mobile touches Supabase directly — auth exchange only)
4. Store access_token + refresh_token in flutter_secure_storage
5. All API calls: Authorization: Bearer <access_token>
6. On 401: auto-refresh via Supabase /auth/v1/token?grant_type=refresh_token
7. Sign-out: POST /api/v1/auth/signout, clear secure storage
```

### Unified requireAuth() for API Routes

```typescript
// web/src/lib/auth.ts
// Handles both cookie session (web) and Bearer header (mobile)
export async function requireAuth(request: NextRequest): Promise<{ userId: string } | NextResponse>
```

---

## 4. Environment Configuration

### Required Variables

```bash
# web/.env.local
NEXT_PUBLIC_SUPABASE_URL=           # Supabase project URL
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=  # Anon key (safe to expose)
SUPABASE_SERVICE_ROLE_KEY=          # Secret — NEVER use NEXT_PUBLIC_ prefix
GNEWS_API_KEY=
CRON_SECRET=                        # openssl rand -hex 32
```

### Flutter Base URL

```dart
// mobile/lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api/v1',  // Android emulator default
  );
}
// flutter run --dart-define=API_BASE_URL=https://nexus.example.com/api/v1
```

---

## 5. Migration Phases

| Phase | Deliverable | Web Status | Mobile Status |
|-------|-------------|------------|---------------|
| **1** | File structure, canonical types, db layer extracted | Unchanged | Mock data |
| **2** | Article API routes + mobile reads real data | Uses API | Real articles |
| **3** | fetch-news migrated to local cron | Edge fn decommissioned | Unchanged |
| **4** | Full Google auth (web + mobile) | Dashboard protected | Login works |
| **5** | User data endpoints (preferences, bookmarks, stats) | Unchanged | Personalisation works |
| **6** | Quiz endpoints | Unchanged | Real questions |
| **7** | Web dashboard UI | Admin interface live | Unchanged |
| **8** | Region / map data from real DB | Map hotspots live | Map live |
| **9** | Cleanup, caching, rate limiting | Production-ready | Production-ready |

---

### Phase 1 — Structural Setup

1. Create `web/src/lib/supabase/` and move the three files from `web/src/utils/supabase/`. Keep the old path as re-export shims temporarily.
2. Create `web/src/types/index.ts` with all canonical types above.
3. Create `web/src/lib/auth.ts` with `requireAuth` stub.
4. Create `web/src/lib/db/articles.ts` and extract the Supabase query from `TrendingFeed` into `getTrendingArticles()`.
5. Update `TrendingFeed` to call `getTrendingArticles()` from the db layer.
6. Create `mobile/lib/config/api_config.dart`.
7. Add `http` or `dio` to `mobile/pubspec.yaml`.
8. Create `mobile/lib/models/article.dart`.

---

### Phase 2 — Article API Routes

1. Create `web/src/app/api/v1/trending/route.ts` → calls `getTrendingArticles()`.
2. Create `web/src/app/api/v1/articles/route.ts` (paginated, filterable).
3. Create `web/src/app/api/v1/articles/[id]/route.ts`.
4. Refactor `TrendingFeed` to call `/api/v1/trending` via `fetch()` instead of db layer directly.
5. Create `mobile/lib/services/articles_service.dart` implementing `fetchTrending()`.
6. Wire `HomeScreen` and `FeedScreen` to `ArticlesService`.

---

### Phase 3 — Migrate fetch-news to Local Cron

1. Create `web/src/lib/gnews.ts` — TypeScript port of the Deno edge function. Replace `Deno.env.get()` with `process.env`. Same upsert logic.
2. Create `web/src/app/api/cron/fetch-news/route.ts` — validates `x-cron-secret` header, calls `gnews.fetchAndIngestAll()`.
3. Add `vercel.json` cron schedule (hourly).
4. Mark `supabase/functions/fetch-news/index.ts` as DEPRECATED.

**What changes Deno → Node:**

| Deno | Next.js |
|------|---------|
| `Deno.env.get("KEY")` | `process.env.KEY` |
| `jsr:@supabase/supabase-js@2` | `@supabase/supabase-js` (already installed) |
| `Deno.serve(...)` | `export async function GET(req: NextRequest)` |
| CORS headers | Not needed (internal route) |

---

### Phase 4 — Auth Integration

1. `web/src/app/(auth)/login/page.tsx` — Google OAuth button.
2. `web/src/app/(auth)/callback/route.ts` — exchange code for session.
3. Update `web/src/middleware.ts` to protect `/(dashboard)/*` routes.
4. Implement `requireAuth()` in `web/src/lib/auth.ts` supporting both cookie (web) and Bearer (mobile).
5. Create auth API routes (`/auth/session`, `/auth/signout`).
6. Flutter: add `google_sign_in`, `flutter_secure_storage`.
7. Create `mobile/lib/services/auth_service.dart` with token refresh interceptor.
8. Add `LoginScreen` to Flutter.

---

### Phase 5 — User Data Endpoints

1. `web/src/lib/db/users.ts` with typed query functions.
2. API routes: `user/preferences`, `user/stats`, `user/bookmarks`.
3. Personalised `/api/v1/feed` filtering by `user_preferences.topics`.
4. Flutter: `user_service.dart`, remaining models.
5. Wire `ProfileScreen`, `FeedScreen`, `ReactionBar` to real data.

---

### Phase 6 — Quiz Endpoints

1. Seed a `quiz_questions` table via migration.
2. `web/src/lib/db/quiz.ts` — `getDailyQuiz()`, `submitQuizAnswers()` (updates `user_stats`).
3. API routes: `/quiz/daily`, `/quiz/submit`.
4. Flutter: `quiz_service.dart`, `quiz_question.dart`.
5. Replace hardcoded `_questions` in `QuizScreen` with real data.

---

### Phase 7 — Web Dashboard UI

1. `web/src/app/(dashboard)/layout.tsx` with sidebar shell.
2. Dashboard pages: overview stats, article list, article detail, user list.
3. Admin middleware: verify `role = 'admin'` in `users` table.
4. Manual fetch-news trigger button in dashboard.
5. Dashboard pages use Server Components calling `lib/db/` directly (no HTTP hop for SSR).

---

### Phase 8 — Regions and Map Data

1. Add `region` column to `articles` table (migration).
2. Update `gnews.ts` to derive region from source country.
3. `web/src/lib/db/regions.ts` with `getRegionCounts()`, `getArticlesByRegion()`.
4. API routes: `/regions`, `/regions/[slug]/articles`.
5. Update `InteractiveMap` to fetch real hotspot counts.
6. Flutter: wire `CountryPanel` to real region articles.

---

### Phase 9 — Cleanup & Hardening

1. Delete `web/src/utils/supabase/` (all imports now in `lib/supabase/`).
2. Remove all hardcoded mock data from Flutter screens.
3. Add proper error boundaries in Flutter.
4. Add `Cache-Control` headers: public routes `s-maxage=60, stale-while-revalidate`, authenticated routes `no-store`.
5. Add rate limiting to API routes.
6. Update `.env.example` to be complete and accurate.

---

## 6. Key Patterns to Enforce

### API Route Handler

```typescript
import { type NextRequest, NextResponse } from 'next/server';
import { getTrendingArticles } from '@/lib/db/articles';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const limit = Math.min(Number(searchParams.get('limit') ?? '20'), 50);

    const { articles, nextCursor } = await getTrendingArticles({ limit });

    return NextResponse.json({ data: articles, meta: { nextCursor } });
  } catch (err) {
    console.error('[GET /api/v1/trending]', err);
    return NextResponse.json(
      { error: { code: 'INTERNAL_ERROR', message: 'Something went wrong' } },
      { status: 500 }
    );
  }
}
```

Rules:
- Always `try/catch` — never leak a stack trace to clients
- Always cap `limit` server-side (max 50)
- Log errors with route prefix for searchability

### DB Layer

```typescript
// web/src/lib/db/articles.ts — typed input/output, no `any`
export async function getTrendingArticles(opts: {
  limit: number;
  cursor?: string;
}): Promise<{ articles: Article[]; nextCursor: string | null }>
```

Rules:
- DB functions are fully typed — no `any`
- Each function does one thing
- Snake_case → camelCase mapping happens here, once, in `rowToArticle()`

### Field Casing

- DB columns: `snake_case` (PostgreSQL)
- API responses: `camelCase` (TypeScript/JavaScript)
- Mapping in `lib/db/*.ts` via `rowToEntity()` helpers — nowhere else

### Flutter Service

```dart
class ArticlesService {
  final ApiClient _client;
  ArticlesService(this._client);

  Future<List<Article>> fetchTrending({ int limit = 20 }) async {
    final response = await _client.get('/trending', queryParameters: { 'limit': limit });
    return (response.data['data'] as List)
        .map((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
```

Rules:
- Services return typed Dart objects, never raw `Map`
- `ApiClient` handles auth headers and token refresh — services are unaware
- Models implement `fromJson` factory constructors

### Flutter Model

```dart
class Article {
  // Fields matching TypeScript types exactly
  factory Article.fromJson(Map<String, dynamic> json) { ... }
}
```

Rules:
- Nullable TypeScript (`string | null`) → nullable Dart (`String?`)
- `DateTime.parse()` for all timestamps
- Field names match camelCase API response keys exactly

### Middleware Route Protection

```typescript
export const config = {
  matcher: [
    '/dashboard/:path*',
    '/api/v1/feed',
    '/api/v1/user/:path*',
    '/api/v1/quiz/:path*',
    '/api/v1/auth/signout',
  ],
};
```

Use an explicit allowlist — routes not in `matcher` are public by default.

---

## 7. Critical Files Reference

| File | Role |
|------|------|
| [web/src/utils/supabase/server.ts](web/src/utils/supabase/server.ts) | Starting point for lib/supabase/server.ts — extend to support Bearer token |
| [supabase/functions/fetch-news/index.ts](supabase/functions/fetch-news/index.ts) | Source of truth for gnews.ts migration |
| [web/src/components/feed/trending-feed.tsx](web/src/components/feed/trending-feed.tsx) | First component to migrate — template for all data-fetching components |
| [supabase/migrations/20260331000000_schema_updates_and_rls.sql](supabase/migrations/20260331000000_schema_updates_and_rls.sql) | Authoritative schema — RLS policies apply to anon key queries |
| [mobile/lib/main.dart](mobile/lib/main.dart) | Root — wire service DI here |
