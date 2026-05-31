-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: fix schema mismatches between DB and API code
-- 2026-05-30
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. journalists.display_name → name ───────────────────────────────────────
-- All API routes expect 'name'; the original column was 'display_name'.
ALTER TABLE public.journalists
  RENAME COLUMN display_name TO name;

-- ── 2. users.role — add default + fix nulls ───────────────────────────────────
-- Column is TEXT with no default; null roles break admin UI and auth guards.
UPDATE public.users SET role = 'user' WHERE role IS NULL;
ALTER TABLE public.users ALTER COLUMN role SET DEFAULT 'user';
ALTER TABLE public.users ALTER COLUMN role SET NOT NULL;

-- ── 3. journalist_badges — add UNIQUE(journalist_id, badge_type) ─────────────
-- Required for the upsert in badge management (onConflict: journalist_id,badge_type).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.journalist_badges'::regclass
      AND contype   = 'u'
      AND conname LIKE '%journalist_id%badge_type%'
  ) THEN
    ALTER TABLE public.journalist_badges
      ADD CONSTRAINT journalist_badges_journalist_id_badge_type_key
      UNIQUE (journalist_id, badge_type);
  END IF;
END;
$$;

-- ── 4. bookmarks — add UNIQUE(user_id, article_id) ────────────────────────────
-- Prevents duplicate bookmarks on rapid double-tap.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.bookmarks'::regclass
      AND contype   = 'u'
      AND conname LIKE '%user_id%article_id%'
  ) THEN
    ALTER TABLE public.bookmarks
      ADD CONSTRAINT bookmarks_user_id_article_id_key
      UNIQUE (user_id, article_id);
  END IF;
END;
$$;

-- ── 5. post_reactions — add UNIQUE(post_id, user_id) ─────────────────────────
-- Prevents duplicate reactions; required for the one-per-user constraint.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'public.post_reactions'::regclass
      AND contype   = 'u'
      AND conname LIKE '%post_id%user_id%'
  ) THEN
    ALTER TABLE public.post_reactions
      ADD CONSTRAINT post_reactions_post_id_user_id_key
      UNIQUE (post_id, user_id);
  END IF;
END;
$$;
