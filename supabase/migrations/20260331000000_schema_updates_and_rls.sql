-- ==========================================
-- PHASE 1 SCHEMA UPDATES & RLS POLICIES
-- ==========================================

-- 1. Alter tables to add missing columns from the Developer Brief
ALTER TABLE public.user_preferences
  ADD COLUMN IF NOT EXISTS topics text[],
  ADD COLUMN IF NOT EXISTS preferred_language text DEFAULT 'en',
  ADD COLUMN IF NOT EXISTS onboarding_complete boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone;

ALTER TABLE public.user_stats
  ADD COLUMN IF NOT EXISTS total_xp integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS current_streak integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS longest_streak integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS quizzes_completed integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS perfect_scores integer DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone;

ALTER TABLE public.digest_prefs
  ADD COLUMN IF NOT EXISTS delivery_time text DEFAULT 'morning',
  ADD COLUMN IF NOT EXISTS email_enabled boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS cohort_key character varying,
  ADD COLUMN IF NOT EXISTS last_read_at timestamp with time zone;


-- 2. Enable Row-Level Security (RLS) and define policies for Phase 1 Tables

-- Table: users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own data" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own data" ON public.users FOR UPDATE USING (auth.uid() = id);

-- Table: user_preferences
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own prefs" ON public.user_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own prefs" ON public.user_preferences FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own prefs" ON public.user_preferences FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Table: articles
ALTER TABLE public.articles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public articles read access" ON public.articles FOR SELECT USING (true);
-- Note: Insert/Update/Delete should only be accessible through Supabase Service Role (Edge Functions), which automatically bypass RLS.

-- Table: news_sources
ALTER TABLE public.news_sources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public news sources read access" ON public.news_sources FOR SELECT USING (is_active = true);

-- Table: bookmarks
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own bookmarks" ON public.bookmarks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own bookmarks" ON public.bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own bookmarks" ON public.bookmarks FOR DELETE USING (auth.uid() = user_id);
