-- ============================================================
-- AUTH OVERHAUL: user_sessions + audit_log
-- Idempotent: safe to re-run.
-- ============================================================

-- ── 1. user_sessions ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_sessions (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_name   TEXT,
  browser       TEXT,
  ip_address    TEXT,
  user_agent    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  revoked_at    TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS user_sessions_user_id_idx ON public.user_sessions (user_id);
CREATE INDEX IF NOT EXISTS user_sessions_active_idx  ON public.user_sessions (user_id) WHERE revoked_at IS NULL;

-- RLS
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_own_sessions_select" ON public.user_sessions;
CREATE POLICY "users_own_sessions_select"
  ON public.user_sessions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_own_sessions_insert" ON public.user_sessions;
CREATE POLICY "users_own_sessions_insert"
  ON public.user_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "users_own_sessions_update" ON public.user_sessions;
CREATE POLICY "users_own_sessions_update"
  ON public.user_sessions FOR UPDATE
  USING (auth.uid() = user_id);

-- Admins can read + update all sessions (for force sign-out)
DROP POLICY IF EXISTS "admins_all_sessions" ON public.user_sessions;
CREATE POLICY "admins_all_sessions"
  ON public.user_sessions FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ── 2. audit_log ──────────────────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'audit_action') THEN
    CREATE TYPE public.audit_action AS ENUM (
      'sign_in',
      'sign_up',
      'sign_out',
      'otp_requested',
      'otp_verified',
      'password_changed',
      'profile_updated',
      'preferences_updated',
      'bookmark_added',
      'bookmark_removed',
      'reaction_added',
      'quiz_submitted',
      'crossword_submitted',
      'session_revoked',
      'all_sessions_revoked',
      'admin_role_changed',
      'admin_ban',
      'admin_force_signout',
      'subscription_created',
      'subscription_cancelled'
    );
  END IF;
END$$;

CREATE TABLE IF NOT EXISTS public.audit_log (
  id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID         REFERENCES auth.users(id) ON DELETE SET NULL,
  action      public.audit_action NOT NULL,
  metadata    JSONB        NOT NULL DEFAULT '{}',
  ip_address  TEXT,
  user_agent  TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS audit_log_user_id_idx    ON public.audit_log (user_id);
CREATE INDEX IF NOT EXISTS audit_log_action_idx     ON public.audit_log (action);
CREATE INDEX IF NOT EXISTS audit_log_created_at_idx ON public.audit_log (created_at DESC);

-- RLS
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Users can read their own audit log
DROP POLICY IF EXISTS "users_own_audit_select" ON public.audit_log;
CREATE POLICY "users_own_audit_select"
  ON public.audit_log FOR SELECT
  USING (auth.uid() = user_id);

-- Service role inserts (all audit writes go through service client)
DROP POLICY IF EXISTS "service_audit_insert" ON public.audit_log;
CREATE POLICY "service_audit_insert"
  ON public.audit_log FOR INSERT
  WITH CHECK (true);

-- Admins can read all
DROP POLICY IF EXISTS "admins_all_audit" ON public.audit_log;
CREATE POLICY "admins_all_audit"
  ON public.audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ── 3. Add sign-up provider column to users if missing ───────────────────────
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS auth_provider TEXT DEFAULT 'email';

-- ── 4. Update handle_new_user to capture provider ─────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
