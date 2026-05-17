-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: journalist role, posts, comments, reactions, badges
-- 2026-05-17
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Link journalists table to a user account ───────────────────────────────
ALTER TABLE public.journalists
  ADD COLUMN IF NOT EXISTS user_id  uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS post_count int NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS journalists_user_id_key ON public.journalists(user_id)
  WHERE user_id IS NOT NULL;

-- ── 2. Journalist posts ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.journalist_posts (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  journalist_id uuid        NOT NULL REFERENCES public.journalists(id) ON DELETE CASCADE,
  title         text        NOT NULL CHECK (char_length(title) BETWEEN 1 AND 200),
  body          text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 10000),
  image_url     text,
  category      text        NOT NULL DEFAULT 'general',
  view_count    int         NOT NULL DEFAULT 0,
  comment_count int         NOT NULL DEFAULT 0,
  reaction_count int        NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS journalist_posts_journalist_id_idx
  ON public.journalist_posts(journalist_id);
CREATE INDEX IF NOT EXISTS journalist_posts_created_at_idx
  ON public.journalist_posts(created_at DESC);

-- ── 3. Post comments ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.post_comments (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     uuid        NOT NULL REFERENCES public.journalist_posts(id) ON DELETE CASCADE,
  author_id   uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body        text        NOT NULL CHECK (char_length(body) BETWEEN 1 AND 1000),
  is_held     boolean     NOT NULL DEFAULT false,
  is_flagged  boolean     NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS post_comments_post_id_idx ON public.post_comments(post_id);
CREATE INDEX IF NOT EXISTS post_comments_author_id_idx ON public.post_comments(author_id);

-- Trigger: keep post comment_count accurate
CREATE OR REPLACE FUNCTION public.sync_post_comment_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.journalist_posts
    SET comment_count = comment_count + 1
    WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.journalist_posts
    SET comment_count = GREATEST(comment_count - 1, 0)
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_post_comment_count ON public.post_comments;
CREATE TRIGGER trg_post_comment_count
  AFTER INSERT OR DELETE ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.sync_post_comment_count();

-- ── 4. Post reactions ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.post_reactions (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid        NOT NULL REFERENCES public.journalist_posts(id) ON DELETE CASCADE,
  user_id    uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type       text        NOT NULL CHECK (type IN ('like','love','wow','sad','angry')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX IF NOT EXISTS post_reactions_post_id_idx ON public.post_reactions(post_id);

-- Trigger: keep post reaction_count accurate
CREATE OR REPLACE FUNCTION public.sync_post_reaction_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.journalist_posts
    SET reaction_count = reaction_count + 1
    WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.journalist_posts
    SET reaction_count = GREATEST(reaction_count - 1, 0)
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_post_reaction_count ON public.post_reactions;
CREATE TRIGGER trg_post_reaction_count
  AFTER INSERT OR DELETE ON public.post_reactions
  FOR EACH ROW EXECUTE FUNCTION public.sync_post_reaction_count();

-- Trigger: keep journalists.post_count accurate
CREATE OR REPLACE FUNCTION public.sync_journalist_post_count()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.journalists
    SET post_count = post_count + 1
    WHERE id = NEW.journalist_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.journalists
    SET post_count = GREATEST(post_count - 1, 0)
    WHERE id = OLD.journalist_id;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_journalist_post_count ON public.journalist_posts;
CREATE TRIGGER trg_journalist_post_count
  AFTER INSERT OR DELETE ON public.journalist_posts
  FOR EACH ROW EXECUTE FUNCTION public.sync_journalist_post_count();

-- ── 5. Journalist badges ──────────────────────────────────────────────────────
-- badge_type thresholds (also enforced in application layer):
--   rising_star  10+  followers (auto-awarded)
--   popular      100+ followers (auto-awarded)
--   gold         500+ followers (auto-awarded)
--   prolific     50+  posts     (auto-awarded)
--   verified     manually awarded by admin (same as is_verified flag, kept for badge display)
--   featured     manually awarded by admin
CREATE TABLE IF NOT EXISTS public.journalist_badges (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  journalist_id uuid        NOT NULL REFERENCES public.journalists(id) ON DELETE CASCADE,
  badge_type    text        NOT NULL CHECK (badge_type IN (
                              'rising_star','popular','gold','prolific','verified','featured'
                            )),
  awarded_at    timestamptz NOT NULL DEFAULT now(),
  awarded_by    uuid        REFERENCES auth.users(id) ON DELETE SET NULL,
  UNIQUE(journalist_id, badge_type)
);

CREATE INDEX IF NOT EXISTS journalist_badges_journalist_id_idx
  ON public.journalist_badges(journalist_id);

-- ── 6. RLS policies ───────────────────────────────────────────────────────────
ALTER TABLE public.journalist_posts  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_comments     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_reactions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journalist_badges ENABLE ROW LEVEL SECURITY;

-- journalist_posts: public read, journalist owns their posts (checked via service role in API)
CREATE POLICY "posts_public_read"   ON public.journalist_posts FOR SELECT USING (true);
CREATE POLICY "posts_service_write" ON public.journalist_posts FOR ALL USING (true) WITH CHECK (true);

-- post_comments: public read of non-held, service role writes
CREATE POLICY "post_comments_public_read" ON public.post_comments
  FOR SELECT USING (is_held = false);
CREATE POLICY "post_comments_service_write" ON public.post_comments
  FOR ALL USING (true) WITH CHECK (true);

-- post_reactions: public read, service role writes
CREATE POLICY "post_reactions_public_read"  ON public.post_reactions FOR SELECT USING (true);
CREATE POLICY "post_reactions_service_write" ON public.post_reactions FOR ALL USING (true) WITH CHECK (true);

-- journalist_badges: public read, service role writes
CREATE POLICY "journalist_badges_public_read"  ON public.journalist_badges FOR SELECT USING (true);
CREATE POLICY "journalist_badges_service_write" ON public.journalist_badges FOR ALL USING (true) WITH CHECK (true);
