-- Make handle_new_user resilient: a trigger failure must never block account creation.
-- Also ensures all required columns exist before the trigger runs.

-- Ensure columns that the trigger writes actually exist
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';

ALTER TABLE public.user_stats
  ADD COLUMN IF NOT EXISTS articles_read INTEGER NOT NULL DEFAULT 0;

-- Redefine the trigger with an EXCEPTION block so any future schema drift
-- logs a warning instead of returning a 500 to the caller.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  BEGIN
    INSERT INTO public.users (id, email, display_name, avatar_url, auth_provider)
    VALUES (
      NEW.id,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name'),
      COALESCE(NEW.raw_user_meta_data ->> 'avatar_url', NEW.raw_user_meta_data ->> 'picture'),
      COALESCE(NEW.app_metadata ->> 'provider', 'email')
    )
    ON CONFLICT (id) DO UPDATE
      SET email         = EXCLUDED.email,
          display_name  = COALESCE(EXCLUDED.display_name, public.users.display_name),
          avatar_url    = COALESCE(EXCLUDED.avatar_url,   public.users.avatar_url),
          auth_provider = COALESCE(EXCLUDED.auth_provider, public.users.auth_provider),
          updated_at    = now();

    INSERT INTO public.user_preferences (user_id, topics, preferred_language, onboarding_complete)
    VALUES (NEW.id, '{}', 'en', false)
    ON CONFLICT (user_id) DO NOTHING;

    INSERT INTO public.user_stats (
      user_id, total_xp, current_streak, longest_streak,
      quizzes_completed, perfect_scores, articles_read
    )
    VALUES (NEW.id, 0, 0, 0, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;

  EXCEPTION WHEN OTHERS THEN
    RAISE WARNING '[handle_new_user] profile setup failed for user %: %', NEW.id, SQLERRM;
  END;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
