-- ─────────────────────────────────────────────────────────────────────────────
-- Migration: fix column names for reactions and comments
-- 2026-07-02
--
-- reactions.reaction_type (enum) → reactions.type (text)
-- comments.text (text)          → comments.body (text)
--
-- Rationale: API routes and client components were written expecting `type`
-- and `body`. The DB had legacy column names from the original schema.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. reactions.reaction_type → reactions.type ───────────────────────────────

-- Drop the unused reaction_counts materialized view first (references reaction_type)
DROP MATERIALIZED VIEW IF EXISTS public.reaction_counts;

-- Cast the enum column to text so we can freely set any string value, then rename
ALTER TABLE public.reactions
  ALTER COLUMN reaction_type TYPE text USING reaction_type::text;

-- Map legacy enum values → new values used by the UI
UPDATE public.reactions
SET reaction_type = CASE reaction_type
  WHEN 'agree'      THEN 'like'
  WHEN 'thoughtful' THEN 'love'
  WHEN 'surprising' THEN 'wow'
  WHEN 'breaking'   THEN 'angry'
  WHEN 'important'  THEN 'wow'
  ELSE 'like'  -- fallback for any other value
END
WHERE reaction_type NOT IN ('like', 'love', 'wow', 'sad', 'angry');

-- Rename column
ALTER TABLE public.reactions
  RENAME COLUMN reaction_type TO type;

-- Add check constraint for valid reaction types
ALTER TABLE public.reactions
  ADD CONSTRAINT reactions_type_check
  CHECK (type IN ('like', 'love', 'wow', 'sad', 'angry'));

-- Recreate the materialized view with the new column name and values
CREATE MATERIALIZED VIEW public.reaction_counts AS
SELECT
  article_id,
  COUNT(*) FILTER (WHERE type = 'like')  AS like_count,
  COUNT(*) FILTER (WHERE type = 'love')  AS love_count,
  COUNT(*) FILTER (WHERE type = 'wow')   AS wow_count,
  COUNT(*) FILTER (WHERE type = 'sad')   AS sad_count,
  COUNT(*) FILTER (WHERE type = 'angry') AS angry_count
FROM public.reactions
GROUP BY article_id;

CREATE UNIQUE INDEX idx_reaction_counts_article
  ON public.reaction_counts(article_id);


-- ── 2. comments.text → comments.body ─────────────────────────────────────────

ALTER TABLE public.comments
  RENAME COLUMN text TO body;

-- Update the RLS policy that references column names (policies reference table
-- values not column names directly, so they don't need updating; just confirm).
