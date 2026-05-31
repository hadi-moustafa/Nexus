-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type        text        NOT NULL CHECK (type IN ('new_comment', 'new_reaction', 'new_post')),
  title       text        NOT NULL,
  body        text,
  post_id     uuid        REFERENCES public.journalist_posts(id) ON DELETE CASCADE,
  read_at     timestamptz,
  created_at  timestamptz DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS notifications_user_id_idx
  ON public.notifications(user_id, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_insert_service" ON public.notifications;
CREATE POLICY "notifications_insert_service" ON public.notifications
  FOR INSERT WITH CHECK (true);

-- ── Trigger: new comment on journalist post ───────────────────────────────────
-- post_comments columns: post_id, author_id (not user_id), body
CREATE OR REPLACE FUNCTION public.notify_journalist_on_comment()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_journalist_user_id uuid;
  v_post_title         text;
  v_commenter_name     text;
BEGIN
  SELECT j.user_id, jp.title
  INTO v_journalist_user_id, v_post_title
  FROM public.journalist_posts jp
  JOIN public.journalists j ON j.id = jp.journalist_id
  WHERE jp.id = NEW.post_id;

  -- Don't notify journalist commenting on their own post
  IF v_journalist_user_id IS NULL OR v_journalist_user_id = NEW.author_id THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = v_journalist_user_id) THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_commenter_name
  FROM public.users WHERE id = NEW.author_id;

  INSERT INTO public.notifications (user_id, type, title, body, post_id)
  VALUES (
    v_journalist_user_id,
    'new_comment',
    COALESCE(v_commenter_name, 'Someone') || ' commented on "' || LEFT(v_post_title, 60) || '"',
    LEFT(NEW.body, 120),
    NEW.post_id
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_comment ON public.post_comments;
CREATE TRIGGER trg_notify_on_comment
  AFTER INSERT ON public.post_comments
  FOR EACH ROW EXECUTE FUNCTION public.notify_journalist_on_comment();

-- ── Trigger: new reaction on journalist post ──────────────────────────────────
-- post_reactions columns: post_id, user_id, type (not reaction_type)
CREATE OR REPLACE FUNCTION public.notify_journalist_on_reaction()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_journalist_user_id uuid;
  v_post_title         text;
  v_reactor_name       text;
  v_emoji              text;
BEGIN
  SELECT j.user_id, jp.title
  INTO v_journalist_user_id, v_post_title
  FROM public.journalist_posts jp
  JOIN public.journalists j ON j.id = jp.journalist_id
  WHERE jp.id = NEW.post_id;

  IF v_journalist_user_id IS NULL OR v_journalist_user_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = v_journalist_user_id) THEN
    RETURN NEW;
  END IF;

  SELECT display_name INTO v_reactor_name
  FROM public.users WHERE id = NEW.user_id;

  v_emoji := CASE NEW.type
    WHEN 'like'  THEN '👍'
    WHEN 'love'  THEN '❤️'
    WHEN 'wow'   THEN '😮'
    WHEN 'sad'   THEN '😢'
    WHEN 'angry' THEN '😠'
    ELSE '👍'
  END;

  INSERT INTO public.notifications (user_id, type, title, body, post_id)
  VALUES (
    v_journalist_user_id,
    'new_reaction',
    COALESCE(v_reactor_name, 'Someone') || ' reacted ' || v_emoji || ' to "' || LEFT(v_post_title, 60) || '"',
    NULL,
    NEW.post_id
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_reaction ON public.post_reactions;
CREATE TRIGGER trg_notify_on_reaction
  AFTER INSERT ON public.post_reactions
  FOR EACH ROW EXECUTE FUNCTION public.notify_journalist_on_reaction();
