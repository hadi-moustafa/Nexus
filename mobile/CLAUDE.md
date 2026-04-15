# Nexus Mobile — Claude Context

## Stack

- **Flutter** (Dart) — iOS, Android, Web
- **Dio** — HTTP client
- **Supabase** — Google OAuth only (no direct DB access from mobile)
- **flutter_secure_storage** — stores access + refresh tokens
- **google_sign_in** — native Google OAuth on iOS/Android

## Architecture Rules

- Mobile **never calls Supabase directly for data** — all data goes through `GET/POST /api/v1/*` on the Next.js backend
- The only Supabase usage on mobile is auth: Google ID token → `signInWithIdToken` → store tokens → send as `Authorization: Bearer <token>` header
- `lib/services/api_client.dart` — singleton Dio client, auto-attaches Bearer token, auto-refreshes on 401
- `lib/services/auth_service.dart` — singleton, handles web (redirect) vs native (google_sign_in) auth split
- `lib/config/api_config.dart` — central config; base URL set via `--dart-define=API_BASE_URL`
- Models in `lib/models/` mirror the TypeScript types in `web/src/types/index.ts` — keep in sync

---

## What Is Done

### Authentication
- [x] Google Sign-In — native path (google_sign_in + Supabase token exchange)
- [x] Google Sign-In — web path (Supabase OAuth redirect)
- [x] Token storage in `flutter_secure_storage`
- [x] Session restore on app launch (`getStoredSession`)
- [x] Automatic token refresh on 401 (`refreshToken` via Supabase REST)
- [x] Auth expiry → redirect to login (via `needsLoginNotifier` in `api_client.dart`)
- [x] Sign-out (server call + local cleanup + Google sign-out)
- [x] Login screen with Google button, loading state, error display (`login_screen.dart`)

### Navigation & App Shell
- [x] Bottom tab navigation — 4 tabs: Home, Feed, Quiz, Profile (`main.dart`)
- [x] App-level auth state management (loading / authenticated / unauthenticated)
- [x] Theme toggle (dark/light) in app bar
- [x] Auth expiry listener → redirects to login

### Home Screen (`home_screen.dart`)
- [x] Trending articles section — fetches from `GET /api/v1/trending` via `ArticlesService`
- [x] Skeleton loaders while articles load
- [x] Interactive world map with tappable region hotspots
- [x] `country_panel.dart` — bottom sheet showing articles for a tapped region (DraggableScrollableSheet)

### Feed Screen (`feed_screen.dart`)
- [x] Article list fetched from `GET /api/v1/articles` with cursor pagination
- [x] Category filter chips (horizontal scrollable)
- [x] Category-based API requests (`category` param, null = "For You")
- [x] `ArticleCard` and `CompactArticleCard` widgets

### Quiz Screen (`quiz_screen.dart`)
- [x] Quiz UI — question display, 4-option answer selection, progress bar
- [x] XP scoring display (10 points per correct answer)
- [x] Answer validation with visual feedback
- [x] Result screen after last question

### Profile Screen (`profile_screen.dart`)
- [x] User avatar display (network image or initials fallback)
- [x] Name and email from `UserProfile` model
- [x] Stats section UI (articles read, quiz score, streak)
- [x] Achievement badges section UI
- [x] Saved articles list UI

### Widgets
- [x] `ArticleCard` — full card with image, category badge, breaking badge, metadata
- [x] `CompactArticleCard` — horizontal compact layout
- [x] `CategoryChip` + `CategoryChipList` — scrollable filter chips
- [x] `AiSummaryCard` — collapsible AI summary with NEXUS AI badge (UI only)
- [x] `ReactionBar` — like, comment, share, bookmark buttons with counts (UI only)

### Models
- [x] `Article` — id, title, summary, content, url, imageUrl, publishedAt, sourceId, category, language, region; `fromJson` + `toJson`
- [x] `UserProfile` — id, email, displayName, avatarUrl, createdAt; `fromJson`; computed `name` and `initials`

### Services
- [x] `ApiClient` — Dio singleton, Bearer auth, 401 refresh, error handling
- [x] `AuthService` — full auth lifecycle (sign-in, refresh, sign-out, token storage)
- [x] `ArticlesService` — `fetchTrending`, `fetchArticles` (paginated + category), `fetchArticleById`

### Theme & Utils
- [x] `NexusColors` — brand teal (#0EC4A0) + amber (#F5A524), full dark/light palette
- [x] `NexusTheme` — light + dark `ThemeData` (AppBar, Card, BottomNav, text styles)
- [x] `DynamicColors` — runtime color helper for theme-aware widgets
- [x] Custom fonts: Fraunces (display/serif), DM Sans (body)
- [x] `timeAgo(DateTime)` utility — human-readable relative time

### Config
- [x] `api_config.dart` — base URL, Supabase URL/key, Google Client ID, timeout; `--dart-define` injection

---

## What Is NOT Done / Needs Work

### Hardcoded Data (must be replaced with real API calls)

- [ ] **Quiz questions** — all 3 questions in `quiz_screen.dart` (lines 19–35) are hardcoded. Wire to `GET /api/v1/quiz/today` and `POST /api/v1/quiz/submit`.
- [ ] **Profile stats** — articles read (248), quiz score (1240), streak (15) in `profile_screen.dart` (lines 164–187) are hardcoded. Fetch from `GET /api/v1/user/stats`.
- [ ] **Saved articles** — 3 fake articles in `profile_screen.dart` (lines 284–300) are hardcoded. Fetch from `GET /api/v1/user/bookmarks`.
- [ ] **Achievement badges** — 4 badges always displayed as owned in `profile_screen.dart` (lines 215–239). Needs backend model and API endpoint.
- [ ] **Premium badge** — always shown in `profile_screen.dart` (lines 113–143). Should check `GET /api/v1/user/subscription`.
- [ ] **Breaking news text** — static string "Breaking: Major diplomatic talks underway in Geneva" in `home_screen.dart` (line 347). Needs a breaking news API endpoint or flag on articles.
- [ ] **Map hotspot counts** — Europe: 24, Asia: 18, Africa: 12, Americas: 31 in `home_screen.dart` (lines 416–448) are hardcoded. Fetch from a region stats endpoint.
- [ ] **Country panel articles** — 5 fake articles in `country_panel.dart` (lines 172–197). Fetch from `GET /api/v1/articles?region=<code>` or similar.
- [ ] **Lebanese Spotlight section** — hardcoded title/source in `feed_screen.dart` (lines 314–326). Wire to real Lebanon category articles.
- [ ] **Feed categories list** — 7 hardcoded strings in `feed_screen.dart` (lines 21–29). Should match the backend category set or be fetched from config.

### Unimplemented UI Buttons (empty `onPressed: () {}`)

- [ ] **Notification bell** — `home_screen.dart` line 125. No notification system exists yet.
- [ ] **"See all" trending** — `home_screen.dart` line 190. Should navigate to a full trending list screen.
- [ ] **Search button** — `feed_screen.dart` line 95. Needs a search screen and `GET /api/v1/search` integration.
- [ ] **Filter button** — `feed_screen.dart` line 99. Advanced filtering UI not built.
- [ ] **Settings button** — `profile_screen.dart` line 48. No settings screen exists.
- [ ] **"See all" saved articles** — `profile_screen.dart` line 264. Needs a dedicated bookmarks screen.

### Missing Screens

- [ ] **Article detail screen** — no screen exists to show a full article. `AiSummaryCard` and `ReactionBar` widgets are built but never used because there is nowhere to show them.
- [ ] **Search screen** — no screen to enter a query and display results from `GET /api/v1/search`.
- [ ] **Bookmarks screen** — full-screen list of saved articles from `GET /api/v1/user/bookmarks`.
- [ ] **Settings screen** — account settings (display name change, sign-out, theme toggle, notification preferences).
- [ ] **Onboarding flow** — no onboarding wizard for new users (topic/language selection). Backend endpoint `PATCH /api/v1/user/preferences` exists but mobile never calls it.
- [ ] **Leaderboard screen** — backend `GET /api/v1/leaderboard` exists but no mobile screen.
- [ ] **Premium / subscription screen** — no paywall or subscription UI on mobile.
- [ ] **Digest screen** — Gemini AI digest exists on web but has no mobile screen.
- [ ] **Journalist profile screen** — `GET /api/v1/journalists/[id]` + follow/unfollow API exists but no mobile screen.

### Missing Services / Models

- [ ] **UserStatsService** — fetch and cache `GET /api/v1/user/stats`
- [ ] **BookmarksService** — fetch `GET /api/v1/user/bookmarks`, add/remove via `POST /api/v1/user/bookmarks`
- [ ] **QuizService** — fetch `GET /api/v1/quiz/today`, submit `POST /api/v1/quiz/submit`
- [ ] **UserPreferencesService** — fetch/update `GET/PATCH /api/v1/user/preferences`
- [ ] **SearchService** — call `GET /api/v1/search`
- [ ] **SubscriptionService** — check `GET /api/v1/user/subscription`
- [ ] **LeaderboardService** — fetch `GET /api/v1/leaderboard`
- [ ] **`UserStats` model** — maps `totalXp`, `currentStreak`, `longestStreak`, `quizzesCompleted`, `perfectScores`, `articlesRead`
- [ ] **`UserPreferences` model** — maps `topics`, `preferredLanguage`, `onboardingComplete`
- [ ] **`Subscription` model** — maps plan, status, endDate

### Reaction Bar & AI Summary Integration
- [ ] `ReactionBar` widget is built but never mounted in any screen (needs article detail screen)
- [ ] `AiSummaryCard` widget is built but never mounted (needs article detail screen)
- [ ] Reactions need wiring to `GET/POST /api/v1/articles/[id]/reactions`
- [ ] Bookmarks in `ReactionBar` need wiring to `POST /api/v1/user/bookmarks`
- [ ] Comments in `ReactionBar` need a comment sheet wired to `GET/POST /api/v1/articles/[id]/comments`

---

## Key File Map

| Purpose | Path |
|---------|------|
| App root + nav | `lib/main.dart` |
| API config | `lib/config/api_config.dart` |
| HTTP client (Dio) | `lib/services/api_client.dart` |
| Auth service | `lib/services/auth_service.dart` |
| Articles service | `lib/services/articles_service.dart` |
| Article model | `lib/models/article.dart` |
| UserProfile model | `lib/models/user_profile.dart` |
| Theme | `lib/theme/app_theme.dart` |
| Time utility | `lib/utils/time_utils.dart` |
| Home screen | `lib/screens/home_screen.dart` |
| Feed screen | `lib/screens/feed_screen.dart` |
| Quiz screen | `lib/screens/quiz_screen.dart` |
| Profile screen | `lib/screens/profile_screen.dart` |
| Login screen | `lib/screens/login_screen.dart` |
| Country panel | `lib/screens/country_panel.dart` |
| Article card widget | `lib/widgets/article_card.dart` |
| Category chip widget | `lib/widgets/category_chip.dart` |
| AI summary widget | `lib/widgets/ai_summary_card.dart` |
| Reaction bar widget | `lib/widgets/reaction_bar.dart` |
