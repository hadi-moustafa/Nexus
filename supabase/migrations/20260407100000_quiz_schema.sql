-- ============================================================
-- QUIZ SCHEMA — ensure quizzes + quiz_questions are complete
-- ============================================================

-- quizzes: base table already exists (id, ...). Add missing columns.
ALTER TABLE public.quizzes
  ADD COLUMN IF NOT EXISTS title        text,
  ADD COLUMN IF NOT EXISTS scheduled_for date NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS is_published  boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS xp_reward     integer NOT NULL DEFAULT 50,
  ADD COLUMN IF NOT EXISTS created_at    timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS idx_quizzes_scheduled ON public.quizzes(scheduled_for);

-- quiz_questions: may not exist yet
CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id        uuid NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
  question       text NOT NULL,
  options        jsonb NOT NULL DEFAULT '[]',  -- string[]
  correct_index  integer NOT NULL,             -- 0-based index into options
  explanation    text,
  time_limit     integer NOT NULL DEFAULT 20,  -- seconds
  position       integer NOT NULL DEFAULT 0,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_quiz_questions_quiz ON public.quiz_questions(quiz_id);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read quiz questions" ON public.quiz_questions
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage quiz questions" ON public.quiz_questions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );
