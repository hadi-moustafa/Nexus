-- ============================================================
-- FULL SRS SCHEMA — Phase 1 Foundation
-- Written against the actual Supabase DB schema.
-- Most tables already exist — this migration only ADDs missing
-- columns and CREATEs the few tables that are truly absent.
-- ============================================================


-- ============================================================
-- 1. ARTICLES — add missing columns
-- The existing table has: id, title, url, source_id (uuid FK),
-- journalist_id (uuid FK), country_code, category, language,
-- ai_summary, published_at, view_count
-- Missing: description, content, thumbnail_url, source_name,
--          cached_at, cache_expires_at
-- ============================================================
ALTER TABLE public.articles
  ADD COLUMN IF NOT EXISTS description       text,
  ADD COLUMN IF NOT EXISTS content           text,
  ADD COLUMN IF NOT EXISTS thumbnail_url     text,
  ADD COLUMN IF NOT EXISTS source_name       text,
  ADD COLUMN IF NOT EXISTS cached_at         timestamptz,
  ADD COLUMN IF NOT EXISTS cache_expires_at  timestamptz;

CREATE INDEX IF NOT EXISTS idx_articles_country_code  ON public.articles(country_code);
CREATE INDEX IF NOT EXISTS idx_articles_category      ON public.articles(category);
CREATE INDEX IF NOT EXISTS idx_articles_published_at  ON public.articles(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_articles_cache_expires ON public.articles(cache_expires_at);


-- ============================================================
-- 2. COMMENTS — add missing columns
-- Existing: id, article_id, author_id, parent_comment_id,
--           text (text), like_count
-- Missing: is_held, is_flagged, edited_at
-- ============================================================
ALTER TABLE public.comments
  ADD COLUMN IF NOT EXISTS is_held   boolean     NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_flagged boolean    NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS edited_at  timestamptz;

CREATE INDEX IF NOT EXISTS idx_comments_article_id ON public.comments(article_id);
CREATE INDEX IF NOT EXISTS idx_comments_author_id  ON public.comments(author_id);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read visible comments" ON public.comments
  FOR SELECT USING (is_held = false OR author_id = auth.uid());

CREATE POLICY "Auth users can insert comments" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = author_id);

CREATE POLICY "Authors can update own recent comments" ON public.comments
  FOR UPDATE USING (
    auth.uid() = author_id
    AND created_at > now() - interval '10 minutes'
  );

CREATE POLICY "Authors can delete own recent comments" ON public.comments
  FOR DELETE USING (
    auth.uid() = author_id
    AND created_at > now() - interval '10 minutes'
  );


-- ============================================================
-- 3. COMMENT LIKES — add RLS (table exists with id, user_id,
--    comment_id, created_at)
-- ============================================================
ALTER TABLE public.comment_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read comment likes" ON public.comment_likes
  FOR SELECT USING (true);

CREATE POLICY "Auth users can like" ON public.comment_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Auth users can unlike" ON public.comment_likes
  FOR DELETE USING (auth.uid() = user_id);


-- ============================================================
-- 4. COMMENT REPORTS — add missing column + RLS
-- Existing: id, comment_id, reporter_id, reason, created_at
-- Missing: resolved
-- ============================================================
ALTER TABLE public.comment_reports
  ADD COLUMN IF NOT EXISTS resolved boolean NOT NULL DEFAULT false;

ALTER TABLE public.comment_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Auth users can report comments" ON public.comment_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Admins can read reports" ON public.comment_reports
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admins can update reports" ON public.comment_reports
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 5. REACTIONS — add missing columns + unique constraint + RLS
-- Existing: id, user_id, article_id, reaction_type (enum),
--           created_at
-- Missing: reacted_at alias, UNIQUE(article_id, user_id)
-- ============================================================
ALTER TABLE public.reactions
  ADD COLUMN IF NOT EXISTS reacted_at timestamptz NOT NULL DEFAULT now();

-- Add unique constraint if not already present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'reactions_article_id_user_id_key'
      AND conrelid = 'public.reactions'::regclass
  ) THEN
    ALTER TABLE public.reactions
      ADD CONSTRAINT reactions_article_id_user_id_key UNIQUE (article_id, user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reactions_article_id ON public.reactions(article_id);

ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read reactions" ON public.reactions
  FOR SELECT USING (true);

CREATE POLICY "Auth users can react" ON public.reactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Auth users can update own reaction" ON public.reactions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Auth users can remove own reaction" ON public.reactions
  FOR DELETE USING (auth.uid() = user_id);


-- ============================================================
-- 6. REACTION COUNTS (materialised view — new)
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.reaction_counts AS
SELECT
  article_id,
  COUNT(*) FILTER (WHERE reaction_type::text = 'breaking')   AS breaking,
  COUNT(*) FILTER (WHERE reaction_type::text = 'agree')      AS agree,
  COUNT(*) FILTER (WHERE reaction_type::text = 'thoughtful') AS thoughtful,
  COUNT(*) FILTER (WHERE reaction_type::text = 'important')  AS important,
  COUNT(*) FILTER (WHERE reaction_type::text = 'surprising') AS surprising
FROM public.reactions
GROUP BY article_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reaction_counts_article
  ON public.reaction_counts(article_id);


-- ============================================================
-- 7. CLUSTERS — add missing columns
-- Existing: id, name, created_at
-- Missing: headline (SRS name), source_count
-- ============================================================
ALTER TABLE public.clusters
  ADD COLUMN IF NOT EXISTS headline     text,
  ADD COLUMN IF NOT EXISTS source_count integer NOT NULL DEFAULT 0;

-- Backfill headline from name
UPDATE public.clusters SET headline = name WHERE headline IS NULL;

ALTER TABLE public.clusters        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cluster_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read clusters"          ON public.clusters         FOR SELECT USING (true);
CREATE POLICY "Public can read cluster_articles"  ON public.cluster_articles FOR SELECT USING (true);


-- ============================================================
-- 8. JOURNALISTS — add missing columns + RLS
-- Existing: id, display_name, bio, photo_url, outlet,
--           article_count
-- Missing: byline_match, is_verified, follower_count
-- ============================================================
ALTER TABLE public.journalists
  ADD COLUMN IF NOT EXISTS byline_match   text,
  ADD COLUMN IF NOT EXISTS is_verified    boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS follower_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS created_at     timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.journalists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read journalists" ON public.journalists
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage journalists" ON public.journalists
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 9. JOURNALIST FOLLOWS — add RLS
-- Existing: id, user_id, journalist_id, created_at
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_journalist_follows_user
  ON public.journalist_follows(user_id);

ALTER TABLE public.journalist_follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own follows" ON public.journalist_follows
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can follow journalists" ON public.journalist_follows
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unfollow journalists" ON public.journalist_follows
  FOR DELETE USING (auth.uid() = user_id);


-- ============================================================
-- 10. QUIZZES — add RLS (table exists with correct columns)
-- ============================================================
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read quizzes" ON public.quizzes
  FOR SELECT USING (true);


-- ============================================================
-- 11. QUIZ RESULTS — add missing columns + RLS
-- Existing: id, user_id, quiz_id, score, xp_earned
-- Missing: answers, streak_day, completed_at
-- ============================================================
ALTER TABLE public.quiz_results
  ADD COLUMN IF NOT EXISTS answers      integer[]   NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS streak_day   integer     NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS completed_at timestamptz NOT NULL DEFAULT now();

-- UNIQUE constraint so a user can only submit each quiz once
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'quiz_results_user_id_quiz_id_key'
      AND conrelid = 'public.quiz_results'::regclass
  ) THEN
    ALTER TABLE public.quiz_results
      ADD CONSTRAINT quiz_results_user_id_quiz_id_key UNIQUE (user_id, quiz_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_quiz_results_user ON public.quiz_results(user_id);

ALTER TABLE public.quiz_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own quiz results" ON public.quiz_results
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own quiz results" ON public.quiz_results
  FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ============================================================
-- 12. USER STATS — add articles_read + RLS
-- ============================================================
ALTER TABLE public.user_stats
  ADD COLUMN IF NOT EXISTS articles_read integer NOT NULL DEFAULT 0;

ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read user stats" ON public.user_stats
  FOR SELECT USING (true);


-- ============================================================
-- 13. BADGES — add missing columns + RLS
-- Existing: id, user_id, badge_type, awarded_at
-- Missing: badge_id (SRS name), label, icon_url, earned_at
-- ============================================================
ALTER TABLE public.badges
  ADD COLUMN IF NOT EXISTS badge_id  varchar,
  ADD COLUMN IF NOT EXISTS label     text,
  ADD COLUMN IF NOT EXISTS icon_url  text,
  ADD COLUMN IF NOT EXISTS earned_at timestamptz;

-- Backfill badge_id from badge_type and earned_at from awarded_at
UPDATE public.badges
  SET badge_id  = badge_type,
      earned_at = awarded_at
  WHERE badge_id IS NULL;

CREATE INDEX IF NOT EXISTS idx_badges_user ON public.badges(user_id);

ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read badges" ON public.badges
  FOR SELECT USING (true);


-- ============================================================
-- 14. SUBSCRIPTIONS — add missing SRS columns + RLS
-- Existing: id, user_id, plan (enum), status (enum),
--           stripe_subscription_id
-- Missing: start_date, end_date, auto_renew, trial_ends_at,
--          stripe_customer_id, updated_at
-- ============================================================
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS start_date            timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS end_date              timestamptz,
  ADD COLUMN IF NOT EXISTS auto_renew            boolean     NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS trial_ends_at         timestamptz,
  ADD COLUMN IF NOT EXISTS stripe_customer_id    text,
  ADD COLUMN IF NOT EXISTS updated_at            timestamptz NOT NULL DEFAULT now();

-- UNIQUE on user_id (one subscription row per user)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'subscriptions_user_id_key'
      AND conrelid = 'public.subscriptions'::regclass
  ) THEN
    ALTER TABLE public.subscriptions ADD CONSTRAINT subscriptions_user_id_key UNIQUE (user_id);
  END IF;
END $$;

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own subscription" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all subscriptions" ON public.subscriptions
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 15. PAYMENTS — add missing SRS columns + RLS
-- Existing: id, user_id, amount (numeric), currency, status
--           (enum), stripe_payment_intent_id, created_at
-- Missing: plan, provider, receipt_url
-- ============================================================
ALTER TABLE public.payments
  ADD COLUMN IF NOT EXISTS plan        text,
  ADD COLUMN IF NOT EXISTS provider    text,
  ADD COLUMN IF NOT EXISTS receipt_url text;

CREATE INDEX IF NOT EXISTS idx_payments_user ON public.payments(user_id);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own payments" ON public.payments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can read all payments" ON public.payments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 16. NEWS SOURCES — add missing column + RLS
-- Existing: id, name, base_url, is_active, category
-- Missing: updated_at
-- ============================================================
ALTER TABLE public.news_sources
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- RLS already partially set up in migration 1; fill gaps
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'news_sources' AND policyname = 'Admins can manage sources'
  ) THEN
    CREATE POLICY "Admins can manage sources" ON public.news_sources
      FOR ALL USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
      );
  END IF;
END $$;


-- ============================================================
-- 17. BOOKMARKS — add unique constraint + RLS gaps
-- Existing: id, user_id, article_id, created_at
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'bookmarks_user_id_article_id_key'
      AND conrelid = 'public.bookmarks'::regclass
  ) THEN
    ALTER TABLE public.bookmarks
      ADD CONSTRAINT bookmarks_user_id_article_id_key UNIQUE (user_id, article_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks(user_id);

-- Ensure RLS is on (was set in migration 1, idempotent)
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- 18. DIGESTS (new table)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.digests (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  cohort_key    varchar     NOT NULL,
  digest_date   date        NOT NULL,
  introduction  text,
  stories       jsonb       NOT NULL DEFAULT '[]',
  article_count integer     NOT NULL DEFAULT 0,
  generated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (cohort_key, digest_date)
);

ALTER TABLE public.digests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read digests" ON public.digests
  FOR SELECT USING (true);


-- ============================================================
-- 19. ANALYTICS DAILY (new table — admin only)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.analytics_daily (
  date           date    PRIMARY KEY,
  active_users   integer NOT NULL DEFAULT 0,
  top_countries  jsonb   NOT NULL DEFAULT '[]',
  top_categories jsonb   NOT NULL DEFAULT '[]',
  api_calls_used integer NOT NULL DEFAULT 0
);

ALTER TABLE public.analytics_daily ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read analytics" ON public.analytics_daily
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 20. API USAGE LOG (new table — admin only)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.api_usage_log (
  id              uuid  PRIMARY KEY DEFAULT gen_random_uuid(),
  source_name     text  NOT NULL,
  endpoint        text,
  calls_made      integer NOT NULL DEFAULT 0,
  calls_remaining integer,
  logged_date     date    NOT NULL DEFAULT CURRENT_DATE
);

ALTER TABLE public.api_usage_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read api usage" ON public.api_usage_log
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 21. LEADERBOARD (new materialised view)
-- ============================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS public.leaderboard AS
SELECT
  us.user_id,
  u.display_name,
  u.avatar_url,
  us.total_xp,
  RANK() OVER (ORDER BY us.total_xp DESC) AS rank
FROM public.user_stats us
JOIN public.users u ON u.id = us.user_id
ORDER BY us.total_xp DESC;

CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_user
  ON public.leaderboard(user_id);


-- ============================================================
-- 22. USERS — ensure RLS policies cover admin reads
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'users' AND policyname = 'Admins can read all users'
  ) THEN
    CREATE POLICY "Admins can read all users" ON public.users
      FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users u WHERE u.id = auth.uid() AND u.role = 'admin')
      );
  END IF;
END $$;
