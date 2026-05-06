# Nexus Mobile — Claude Context

## Stack

- **Flutter** (Dart) — iOS, Android, Web
- **Dio** — HTTP client
- **Supabase Flutter** — Auth only (OAuth redirect + email/password; session managed by supabase_flutter)
- **url_launcher** — opens article URLs in external browser

## Architecture Rules

- Mobile **never calls Supabase directly for data** — all data goes through `GET/POST /api/v1/*` on the Next.js backend
- Auth uses Supabase OAuth redirect flow (PKCE on native, implicit on web) — no `google_sign_in` package
- Session (access + refresh tokens) is persisted automatically by `supabase_flutter` — no manual token storage
- `lib/services/api_client.dart` — singleton Dio client, auto-attaches Bearer token, auto-refreshes on 401
- `lib/services/auth_service.dart` — singleton; `signInWithGoogle`, `signInWithEmail`, `signUpWithEmail`, `resendConfirmationEmail`, session management
- `lib/config/api_config.dart` — central config; base URL set via `--dart-define=API_BASE_URL`
- Models in `lib/models/` mirror the TypeScript types in `web/src/types/index.ts` — keep in sync

## Android OAuth Deep-Link Setup

- Scheme: `com.example.nexus`, host: `login-callback` → `com.example.nexus://login-callback/`
- Intent filter in `AndroidManifest.xml` handles the Supabase redirect
- **Supabase Dashboard** must have `com.example.nexus://login-callback/` in Auth → URL Configuration → Redirect URLs
- Uses `AuthFlowType.pkce` on native (preserves `?code=` in deep-link), `AuthFlowType.implicit` on web
- Uses `authScreenLaunchMode: LaunchMode.externalApplication` on Android (real Chrome, not Custom Tab)

---

## What Is Done

### Authentication
- [x] Google Sign-In via Supabase OAuth redirect (native PKCE + web implicit)
- [x] Email/password sign-in (`signInWithPassword`)
- [x] Email/password sign-up (`signUp` → immediate sign-in attempt → confirmation fallback)
- [x] Resend confirmation email (`resendConfirmationEmail`)
- [x] Session restore on app launch (`getStoredSession`)
- [x] Automatic token refresh on 401 (`refreshToken`)
- [x] Auth expiry → redirect to login (via `needsLoginNotifier` in `api_client.dart`)
- [x] Sign-out

### Login Screen (`login_screen.dart`)
- [x] Tab bar: Sign In / Sign Up
- [x] Email + password sign-in form with validation
- [x] Email + password + confirm-password sign-up form
- [x] "Check your inbox" state with resend email button
- [x] Google OAuth button with "browser open / waiting" state and Cancel
- [x] Friendly error messages mapped from Supabase error strings

### Navigation & App Shell
- [x] Bottom tab navigation — 4 tabs: Home, Feed, Quiz, Profile (`main.dart`)
- [x] App-level auth state management (loading / authenticated / unauthenticated)
- [x] Theme toggle (dark/light)
- [x] Auth expiry listener → redirects to login

### Home Screen (`home_screen.dart`)
- [x] Trending articles → `GET /api/v1/trending` (skeleton loaders)
- [x] Interactive world map with tappable region hotspots
- [x] `country_panel.dart` — DraggableScrollableSheet with region articles

### Feed Screen (`feed_screen.dart`)
- [x] Article list → `GET /api/v1/articles` with cursor pagination
- [x] Category filter chips (horizontal scrollable)
- [x] Search icon → `SearchScreen`
- [x] Article cards tap → `ArticleScreen`

### Quiz Screen (`quiz_screen.dart`)
- [x] Fetches from `GET /api/v1/quiz/today`
- [x] State machine: loading → play → per-question reveal → submit → results
- [x] Submits to `POST /api/v1/quiz/submit`
- [x] Handles `alreadyCompleted`, no-quiz-today, 409 duplicate-submission

### Profile Screen (`profile_screen.dart`)
- [x] Real stats → `GET /api/v1/user/stats` (skeleton loaders, pull-to-refresh)
- [x] Real bookmarks → `GET /api/v1/user/bookmarks` (skeleton loaders)

### Article Screen (`article_screen.dart`)
- [x] Full article detail: hero image, category badge, summary/content
- [x] Bookmark toggle → `UserService.toggleBookmark`
- [x] "Read Full Article" button → `url_launcher`

### Search Screen (`search_screen.dart`)
- [x] TextField in AppBar, skeleton loaders
- [x] Results tap → `ArticleScreen`
- [x] Calls `GET /api/v1/search`

### Services
- [x] `ApiClient` — Dio singleton, Bearer auth, 401 refresh, error handling
- [x] `AuthService` — full auth lifecycle
- [x] `ArticlesService` — `fetchTrending`, `fetchArticles`, `fetchArticleById`, `searchArticles`
- [x] `QuizService` — `fetchTodaysQuiz`, `submitQuiz`
- [x] `UserService` — `fetchStats`, `fetchBookmarks`, `toggleBookmark`

### Models
- [x] `Article`, `UserProfile`, `QuizQuestion`, `DailyQuiz`, `QuizResult`, `UserStats`, `BookmarkedArticle`

### Theme & Utils
- [x] `NexusColors`, `NexusTheme` (light/dark), `DynamicColors`
- [x] Custom fonts: Fraunces, DM Sans
- [x] `timeAgo(DateTime)` utility

---

## What Is NOT Done / Needs Work

### Hardcoded Data (still needs real API)
- [ ] Breaking news text in `home_screen.dart` — static string, needs `/api/v1/feed` breaking flag
- [ ] Map hotspot counts in `home_screen.dart` — hardcoded (Europe: 24, Asia: 18, etc.)
- [ ] Country panel articles in `country_panel.dart` — fake articles, needs `GET /api/v1/articles?region=<code>`
- [ ] Achievement badges in `profile_screen.dart` — always shown as owned, needs backend model

### Missing Screens
- [ ] **Settings screen** — display name change, sign-out, theme toggle, notification prefs
- [ ] **Onboarding flow** — topic/language selection wizard calling `PATCH /api/v1/user/preferences`
- [ ] **Leaderboard screen** — `GET /api/v1/leaderboard`
- [ ] **Bookmarks screen** — full-screen paginated bookmarks list
- [ ] **Premium/subscription screen** — paywall UI, `GET /api/v1/user/subscription`

### Unimplemented Buttons
- [ ] Notification bell — `home_screen.dart` (no notification system)
- [ ] "See all" trending — `home_screen.dart`
- [ ] Settings button — `profile_screen.dart`
- [ ] "See all" saved articles — `profile_screen.dart`

---

## Key File Map

| Purpose | Path |
|---------|------|
| App root + nav | `lib/main.dart` |
| API config | `lib/config/api_config.dart` |
| HTTP client (Dio) | `lib/services/api_client.dart` |
| Auth service | `lib/services/auth_service.dart` |
| Articles service | `lib/services/articles_service.dart` |
| Quiz service | `lib/services/quiz_service.dart` |
| User service | `lib/services/user_service.dart` |
| Article model | `lib/models/article.dart` |
| Quiz models | `lib/models/quiz.dart` |
| UserProfile model | `lib/models/user_profile.dart` |
| UserStats model | `lib/models/user_stats.dart` |
| Theme | `lib/theme/app_theme.dart` |
| Time utility | `lib/utils/time_utils.dart` |
| Home screen | `lib/screens/home_screen.dart` |
| Feed screen | `lib/screens/feed_screen.dart` |
| Quiz screen | `lib/screens/quiz_screen.dart` |
| Profile screen | `lib/screens/profile_screen.dart` |
| Login screen | `lib/screens/login_screen.dart` |
| Article screen | `lib/screens/article_screen.dart` |
| Search screen | `lib/screens/search_screen.dart` |
| Country panel | `lib/screens/country_panel.dart` |
| Article card widget | `lib/widgets/article_card.dart` |
| Category chip widget | `lib/widgets/category_chip.dart` |
| AI summary widget | `lib/widgets/ai_summary_card.dart` |
| Reaction bar widget | `lib/widgets/reaction_bar.dart` |
