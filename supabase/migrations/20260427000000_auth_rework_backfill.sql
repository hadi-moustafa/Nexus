-- ============================================================
-- AUTH REWORK — ensure trigger is correct + backfill
-- Idempotent: safe to re-run.
-- ============================================================

-- 1. Re-create trigger function (CREATE OR REPLACE is idempotent)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name'),
    COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture')
  )
  ON CONFLICT (id) DO UPDATE
    SET email        = EXCLUDED.email,
        display_name = COALESCE(EXCLUDED.display_name, public.users.display_name),
        avatar_url   = COALESCE(EXCLUDED.avatar_url,   public.users.avatar_url),
        updated_at   = now();

  INSERT INTO public.user_preferences (user_id, topics, preferred_language, onboarding_complete)
  VALUES (NEW.id, '{}', 'en', false)
  ON CONFLICT (user_id) DO NOTHING;

  INSERT INTO public.user_stats (
    user_id, total_xp, current_streak, longest_streak,
    quizzes_completed, perfect_scores, articles_read
  )
  VALUES (NEW.id, 0, 0, 0, 0, 0, 0)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- 2. Re-attach trigger (idempotent)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 3. Sync trigger — keep email + avatar in sync on auth.users UPDATE
CREATE OR REPLACE FUNCTION public.handle_user_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users
  SET
    email      = NEW.email,
    avatar_url = COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture', avatar_url),
    updated_at = now()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_update();

-- 4. Backfill: create missing rows for all existing auth users
INSERT INTO public.users (id, email, display_name, avatar_url)
SELECT
  id,
  email,
  COALESCE(raw_user_meta_data ->> 'full_name', raw_user_meta_data ->> 'name'),
  COALESCE(raw_user_meta_data ->> 'avatar_url', raw_user_meta_data ->> 'picture')
FROM auth.users
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_preferences (user_id, topics, preferred_language, onboarding_complete)
SELECT id, '{}', 'en', false
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO public.user_stats (
  user_id, total_xp, current_streak, longest_streak,
  quizzes_completed, perfect_scores, articles_read
)
SELECT id, 0, 0, 0, 0, 0, 0
FROM auth.users
ON CONFLICT (user_id) DO NOTHING;
