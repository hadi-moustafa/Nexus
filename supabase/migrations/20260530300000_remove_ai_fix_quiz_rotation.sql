-- =============================================================
-- Migration: Remove AI features, fix quiz rotation constraint
-- =============================================================

BEGIN;

-- 1. Drop the AI digest infrastructure
DROP TABLE IF EXISTS public.digests CASCADE;
DROP TABLE IF EXISTS public.digest_prefs CASCADE;

-- 2. Drop ai_summary column from articles (no longer used)
ALTER TABLE public.articles
  DROP COLUMN IF EXISTS ai_summary;

-- 3. Fix quiz_results unique constraint so the same quiz can be
--    redone on a future day (rotation). Old constraint prevented
--    ever re-doing the same quiz_id. New constraint: one quiz per
--    user per UTC calendar day.
ALTER TABLE public.quiz_results
  DROP CONSTRAINT IF EXISTS quiz_results_quiz_id_user_id_key,
  DROP CONSTRAINT IF EXISTS quiz_results_user_day_key;

ALTER TABLE public.quiz_results
  ADD CONSTRAINT quiz_results_user_day_key
    UNIQUE (user_id, (completed_at AT TIME ZONE 'UTC')::date);

COMMIT;
