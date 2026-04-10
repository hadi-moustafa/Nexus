-- ============================================================
-- FIX MISSING RLS POLICIES
-- Adds INSERT + UPDATE policies that were absent, causing 42501
-- errors on quiz submit, crossword completion, and stat updates.
-- ============================================================


-- ============================================================
-- 1. USER_STATS — authenticated users can insert/update own row
-- ============================================================
CREATE POLICY "Auth users can insert own stats" ON public.user_stats
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Auth users can update own stats" ON public.user_stats
  FOR UPDATE USING (auth.uid() = user_id);


-- ============================================================
-- 2. SUBSCRIPTIONS — users can update own row (for cancel flow)
-- ============================================================
CREATE POLICY "Users can update own subscription" ON public.subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscription" ON public.subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ============================================================
-- 3. CROSSWORD_RESULTS — already has INSERT + UPDATE from
--    20260410000000, but adding UPDATE policy explicitly
--    in case it was missed.
-- ============================================================
-- (policies already created in previous migration — no-op here)


-- ============================================================
-- 4. GENERAL_QUIZ_RESULTS — already has INSERT policy.
-- ============================================================
-- (policies already created in previous migration — no-op here)
