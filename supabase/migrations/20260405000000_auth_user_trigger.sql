-- ============================================================
-- AUTH USER TRIGGER + USERS TABLE ADDITIONS
-- ============================================================
-- Ensures that every Supabase Auth sign-in (Google OAuth from
-- BOTH web and mobile) automatically creates matching rows in
-- public.users, user_preferences, and user_stats.
--
-- This trigger is the single source of truth for user creation
-- regardless of which client initiated the sign-in.
-- ============================================================


-- 1. Add missing columns to public.users
--    (base table was created before this migration)
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS avatar_url   text,
  ADD COLUMN IF NOT EXISTS role         text NOT NULL DEFAULT 'user',
  ADD COLUMN IF NOT EXISTS updated_at   timestamptz NOT NULL DEFAULT now();

-- Add INSERT policy that was missing from the first migration
-- (the trigger runs as SECURITY DEFINER so it bypasses RLS,
-- but this is needed for direct inserts from the app if ever required)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'users' AND policyname = 'Users can insert own row'
  ) THEN
    CREATE POLICY "Users can insert own row"
      ON public.users FOR INSERT
      WITH CHECK (auth.uid() = id);
  END IF;
END $$;


-- 2. Trigger function
--    Fires AFTER INSERT on auth.users — i.e. every time a new user
--    signs up or signs in for the first time via any OAuth provider.
--
--    raw_user_meta_data is populated by Supabase with the Google
--    profile fields: full_name, avatar_url, email, etc.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER          -- runs with the privileges of the function owner,
SET search_path = public  -- not the calling user, so it can write to public.*
AS $$
BEGIN
  -- Upsert into public.users
  -- ON CONFLICT handles the rare case where the trigger fires more than once
  -- for the same user (e.g. after an account merge or re-invite).
  INSERT INTO public.users (id, email, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data ->> 'full_name',
    NEW.raw_user_meta_data ->> 'avatar_url'
  )
  ON CONFLICT (id) DO UPDATE
    SET email        = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, public.users.display_name),
        avatar_url   = COALESCE(EXCLUDED.avatar_url,   public.users.avatar_url),
        updated_at   = now();

  -- Create default user_preferences row (idempotent)
  INSERT INTO public.user_preferences (user_id, topics, preferred_language, onboarding_complete)
  VALUES (NEW.id, '{}', 'en', false)
  ON CONFLICT DO NOTHING;

  -- Create default user_stats row (idempotent)
  INSERT INTO public.user_stats (
    user_id, total_xp, current_streak, longest_streak,
    quizzes_completed, perfect_scores
  )
  VALUES (NEW.id, 0, 0, 0, 0, 0)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$;


-- 3. Attach trigger to auth.users
--    Drop first so re-running this migration is safe.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
