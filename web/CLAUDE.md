@AGENTS.md

# Nexus Web — Claude Context

## Stack

- **Next.js 16.2** (App Router), **React 19**, **TypeScript**, **TailwindCSS 4**
- **Supabase** — PostgreSQL + Google OAuth only (no Edge Functions)
- **Stripe** — subscription billing
- **Google Gemini** — AI digest generation
- **Guardian / GNews** — news ingestion sources

## Architecture Rules

- `lib/db/*.ts` — all DB access goes here; **snake_case → camelCase mapping happens once here**
- `app/api/v1/*` — REST API serving both web frontend and Flutter mobile
- Server Components call `lib/db/` directly (no HTTP hop)
- `lib/auth.ts` → `requireAuth()` — handles both cookie (web) and Bearer header (mobile)
- `lib/admin.ts` → `requireAdminPage()` / `requireAdminApi()` — admin guards
- `src/types/index.ts` — canonical TypeScript types; keep in sync with DB schema

---

## What Is Done

### Authentication
- [x] Google OAuth sign-in (`/app/(auth)/login/page.tsx`)
- [x] OAuth callback handler (`/api/v1/auth/callback`)
- [x] Cookie-based session (Supabase SSR)
- [x] Email/password change endpoint (`/api/v1/auth/change-password`) — email provider only
- [x] Sign-out endpoint (`/api/v1/auth/signout`)
- [x] Session info endpoint (`/api/v1/auth/session`)
- [x] `requireAuth()` supporting both cookie and Bearer token
- [x] Admin guards with role check

### Feed & Articles
- [x] Trending articles (`/api/v1/trending`, `trending-feed.tsx` server component)
- [x] Paginated article feed with cursor-based pagination (`/api/v1/feed`)
- [x] "For You" tab auto-loads user topic preferences
- [x] Category filtering — 10 tabs (For You, Lebanon, العربية, World, Tech, Business, Sports, Science, Health, Entertainment)
- [x] Virtual "lebanon" category — triggers keyword search on title/description in EN + AR
- [x] Full-text search (`/api/v1/search`) on title + description with category filter
- [x] Article detail page (`/app/article/[id]`) — metadata, read time, AI summary banner, journalist link
- [x] `article-card.tsx`, `article-skeleton.tsx`, `breaking-news-banner.tsx`
- [x] Country/region news page (`/app/country/[code]`)
- [x] Interactive map component (`interactive-map.tsx`)

### User & Profile
- [x] Profile read/update (`/api/v1/user/profile`) — display name change
- [x] User preferences read/update (`/api/v1/user/preferences`) — topics, language, onboarding flag
- [x] User stats (`/api/v1/user/stats`) — XP, streak, quiz count, perfect scores, articles read
- [x] Onboarding 3-step wizard (`/app/onboarding`) — topics, language, notifications consent
- [x] Profile page (`/app/profile`) — display name, avatar, password change, onboarding status check

### Bookmarks
- [x] Add/remove bookmarks (`POST /api/v1/user/bookmarks`)
- [x] Paginated bookmark list with article details (`GET /api/v1/user/bookmarks`)

### Comments & Reactions
- [x] Comment list + post (`GET/POST /api/v1/articles/[id]/comments`)
- [x] Comment delete (`DELETE /api/v1/articles/[id]/comments/[commentId]`)
- [x] Reaction system — like, love, wow, sad, angry (`GET/POST /api/v1/articles/[id]/reactions`)
- [x] `comments-section.tsx`, `reactions-bar.tsx` components

### Journalists
- [x] Journalist profile page (`/app/journalist/[id]`) — bio, verified badge, follower count, articles
- [x] Follow/unfollow (`POST/DELETE /api/v1/journalists/[id]/follow`)
- [x] Journalist API (`/api/v1/journalists/[id]`)

### Gamification
- [x] Daily quiz (`GET /api/v1/quiz/today`, `POST /api/v1/quiz/submit`) — server-side scoring, XP + streak
- [x] General quiz pool (`GET /api/v1/quiz/general`, `POST /api/v1/quiz/general/submit`)
- [x] Crossword puzzle page (`/app/crossword`) — 5×5 grid, timer, check/reveal/reset
- [x] Crossword submission (`POST /api/v1/crossword/submit`) — XP + streak award
- [x] Leaderboard page (`/app/leaderboard`) — top users by XP, podium, pagination
- [x] Leaderboard API (`GET /api/v1/leaderboard`) — with current user rank
- [x] Animated mascot component (`mascot.tsx`) — neutral/happy/excited/sad/thinking states

### Premium / Stripe
- [x] Premium page (`/app/premium`) — monthly ($4.99) and annual ($39.99) plan selection
- [x] Stripe checkout session creation (`POST /api/v1/stripe/checkout`)
- [x] Stripe session verification & subscription activation (`POST /api/v1/stripe/verify-session`)
- [x] Stripe webhook handler (`GET /api/v1/stripe/webhook`) — subscription lifecycle events
- [x] Subscription status endpoint (`GET /api/v1/user/subscription`)
- [x] AI daily digest (`/app/digest`) — Gemini-generated, premium-gated
- [x] Digest API (`GET /api/v1/digest`) — on-demand generation with 24h → 7d → all articles fallback
- [x] Manual digest generation endpoint (`POST /api/v1/internal/generate-digest`)

### News Ingestion
- [x] Guardian API ingestion (`lib/guardian.ts`) — 8+ sections mapped to categories
- [x] GNews API client (`lib/gnews.ts`)
- [x] Cron job endpoint (`POST /api/cron/fetch-news`)
- [x] Manual fetch endpoint (`POST /api/v1/internal/fetch-news`)

### Admin Panel
- [x] Admin sidebar layout with navigation
- [x] Dashboard with stat cards + recent sign-ups (`/app/admin`)
- [x] User management — list, update role, ban (`/app/admin/users`, `/api/v1/admin/users/[userId]`)
- [x] News source management — CRUD (`/app/admin/sources`)
- [x] Flagged comments moderation — review, delete (`/app/admin/comments`)
- [x] Journalist management — create, edit, delete (`/app/admin/journalists`)
- [x] Subscription overview (`/app/admin/subscriptions`)
- [x] Quiz creation/management — create, edit, delete (`/app/admin/quiz`)

### UI/Theme
- [x] Light/dark mode (`theme-provider.tsx` via next-themes)
- [x] Navbar with logo, nav links, theme toggle, user menu

---

## What Is NOT Done / Needs Work

### Hardcoded Content (needs backend wiring)
- [ ] **Crossword puzzle** — grid, answers, and clues are fully hardcoded in `app/crossword/page.tsx` (lines 24–49). Needs dynamic crossword from DB or admin-generated content.
- [ ] **Feed categories** — hardcoded array in `app/feed/page.tsx` (lines 14–25). Should come from config or DB.
- [ ] **Onboarding topics** — hardcoded 8-item list in `app/onboarding/page.tsx` (lines 7–16). Should be driven by DB or config.
- [ ] **Onboarding languages** — only 3 hardcoded options (en, ar, fr). Expand or make configurable.

### Missing Features
- [ ] **Email/password sign-up flow** — there is no registration page; only Google OAuth is available. Email provider path is only partially supported.
- [ ] **Email verification** — no email verification workflow exists.
- [ ] **Avatar upload** — profile page shows avatar but no upload mechanism.
- [ ] **Notification system** — no push/in-app notification infrastructure exists.
- [ ] **Article read tracking** — `articlesRead` stat exists in `UserStats` but no endpoint/trigger to increment it.
- [ ] **Breaking news source** — `breaking-news-banner.tsx` exists but no API endpoint feeds it live data.
- [ ] **Country panel on web map** — `interactive-map.tsx` exists; unclear if clicking a region loads a country panel similar to mobile.

### Robustness / Edge Cases
- [ ] **Rate limiting** — no rate limiting on any API route (search, reactions, comments, quiz submission).
- [ ] **Idempotency on bookmarks** — rapid double-tap could create duplicate records; no idempotency key.
- [ ] **Quiz double-submission** — client-side guard exists but no server-side idempotency.
- [ ] **Stripe webhook ordering** — no handling for webhook arriving before subscription record is created.
- [ ] **Arabic category** ("العربية") — relies on `language = 'ar'` filter; verify DB has Arabic-language articles being ingested.
- [ ] **Journalist byline matching** — exact string match only; fuzzy/partial matching not implemented.

### Performance
- [ ] **No caching headers** on GET API routes — every request hits DB.
- [ ] **No `revalidate` / ISR** on static-ish pages (leaderboard, journalist profiles).

---

## Key File Map

| Purpose | Path |
|---------|------|
| Canonical types | `src/types/index.ts` |
| Auth helper | `src/lib/auth.ts` |
| Admin guard | `src/lib/admin.ts` |
| Article DB queries | `src/lib/db/articles.ts` |
| User DB queries | `src/lib/db/users.ts` |
| Stripe client + plans | `src/lib/stripe.ts` |
| Gemini digest gen | `src/lib/gemini.ts` |
| Guardian ingestion | `src/lib/guardian.ts` |
| GNews client | `src/lib/gnews.ts` |
| Supabase server client | `src/lib/supabase/server.ts` |
| Supabase browser client | `src/lib/supabase/client.ts` |
| All API routes | `src/app/api/v1/` |
| Admin pages | `src/app/admin/` |
| Auth pages | `src/app/(auth)/` |
