-- ============================================================
-- GENERAL QUIZ + CROSSWORD SCHEMA
-- Adds: general_questions, general_quiz_results, crossword_results
--       last_activity_date on user_stats
--       stripe_subscription_id on subscriptions
-- ============================================================


-- ============================================================
-- 1. SUBSCRIPTIONS — add stripe_subscription_id if missing
-- ============================================================
ALTER TABLE public.subscriptions
  ADD COLUMN IF NOT EXISTS stripe_subscription_id text;


-- ============================================================
-- 2. USER_STATS — add last_activity_date for streak tracking
-- ============================================================
ALTER TABLE public.user_stats
  ADD COLUMN IF NOT EXISTS last_activity_date date;

CREATE INDEX IF NOT EXISTS idx_user_stats_user ON public.user_stats(user_id);


-- ============================================================
-- 3. GENERAL_QUESTIONS — seeded question bank (3 tiers)
--    difficulty: 'easy' | 'medium' | 'hard'
--    xp_value:   easy=10, medium=20, hard=40
-- ============================================================
CREATE TABLE IF NOT EXISTS public.general_questions (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  question    text        NOT NULL,
  options     jsonb       NOT NULL DEFAULT '[]',  -- string[4]
  correct_index integer   NOT NULL,               -- 0-based
  explanation text,
  difficulty  text        NOT NULL DEFAULT 'easy'
                          CHECK (difficulty IN ('easy','medium','hard')),
  category    text        NOT NULL DEFAULT 'general',
  xp_value    integer     NOT NULL DEFAULT 10,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.general_questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read general questions" ON public.general_questions
  FOR SELECT USING (true);

CREATE POLICY "Admins can manage general questions" ON public.general_questions
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );


-- ============================================================
-- 4. GENERAL_QUIZ_RESULTS — one row per user per session
-- ============================================================
CREATE TABLE IF NOT EXISTS public.general_quiz_results (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  difficulty      text        NOT NULL CHECK (difficulty IN ('easy','medium','hard')),
  score           integer     NOT NULL DEFAULT 0,
  total           integer     NOT NULL DEFAULT 5,
  xp_earned       integer     NOT NULL DEFAULT 0,
  answers         jsonb       NOT NULL DEFAULT '[]',  -- number[] selected indices
  completed_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_general_quiz_results_user ON public.general_quiz_results(user_id);
CREATE INDEX IF NOT EXISTS idx_general_quiz_results_date ON public.general_quiz_results(completed_at DESC);

ALTER TABLE public.general_quiz_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own general quiz results" ON public.general_quiz_results
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Auth users can insert general quiz results" ON public.general_quiz_results
  FOR INSERT WITH CHECK (auth.uid() = user_id);


-- ============================================================
-- 5. CROSSWORD_RESULTS — one row per user per day
-- ============================================================
CREATE TABLE IF NOT EXISTS public.crossword_results (
  id              uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  puzzle_date     date        NOT NULL DEFAULT CURRENT_DATE,
  completed       boolean     NOT NULL DEFAULT false,
  xp_earned       integer     NOT NULL DEFAULT 0,
  time_seconds    integer,
  completed_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, puzzle_date)
);

CREATE INDEX IF NOT EXISTS idx_crossword_results_user ON public.crossword_results(user_id);

ALTER TABLE public.crossword_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own crossword results" ON public.crossword_results
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Auth users can insert crossword results" ON public.crossword_results
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Auth users can update own crossword results" ON public.crossword_results
  FOR UPDATE USING (auth.uid() = user_id);


-- ============================================================
-- 6. SEED — 45 general knowledge questions (15 per tier)
-- ============================================================

-- EASY (xp_value = 10)
INSERT INTO public.general_questions (question, options, correct_index, explanation, difficulty, category, xp_value) VALUES
  ('What is the capital of France?',
   '["London","Berlin","Paris","Rome"]', 2, 'Paris has been the capital of France since 987 AD.', 'easy', 'geography', 10),
  ('How many continents are there on Earth?',
   '["5","6","7","8"]', 2, 'The seven continents are Africa, Antarctica, Asia, Australia, Europe, North America, and South America.', 'easy', 'geography', 10),
  ('Which planet is known as the Red Planet?',
   '["Venus","Mars","Jupiter","Saturn"]', 1, 'Mars gets its red color from iron oxide (rust) on its surface.', 'easy', 'science', 10),
  ('What is 12 × 12?',
   '["124","132","144","154"]', 2, '12 × 12 = 144.', 'easy', 'math', 10),
  ('Who wrote "Romeo and Juliet"?',
   '["Charles Dickens","William Shakespeare","Jane Austen","Mark Twain"]', 1, 'Romeo and Juliet was written by William Shakespeare around 1594–1596.', 'easy', 'literature', 10),
  ('What is the chemical symbol for water?',
   '["O2","H2O","CO2","NaCl"]', 1, 'Water is composed of two hydrogen atoms and one oxygen atom: H₂O.', 'easy', 'science', 10),
  ('Which ocean is the largest?',
   '["Atlantic","Indian","Arctic","Pacific"]', 3, 'The Pacific Ocean is the largest ocean, covering about 165 million km².', 'easy', 'geography', 10),
  ('How many days are in a leap year?',
   '["364","365","366","367"]', 2, 'A leap year has 366 days, with February having 29 days.', 'easy', 'general', 10),
  ('What color do you get when mixing red and blue?',
   '["Green","Orange","Purple","Brown"]', 2, 'Red and blue mixed together produce purple (violet).', 'easy', 'art', 10),
  ('What is the largest mammal on Earth?',
   '["Elephant","Blue Whale","Giraffe","Hippopotamus"]', 1, 'The blue whale is the largest mammal — and the largest animal — on Earth.', 'easy', 'science', 10),
  ('In which country is the Great Wall located?',
   '["Japan","India","China","Mongolia"]', 2, 'The Great Wall of China stretches over 21,000 km across northern China.', 'easy', 'history', 10),
  ('How many sides does a hexagon have?',
   '["5","6","7","8"]', 1, 'A hexagon has 6 sides.', 'easy', 'math', 10),
  ('Which gas do plants absorb from the atmosphere?',
   '["Oxygen","Nitrogen","Carbon Dioxide","Hydrogen"]', 2, 'Plants absorb CO₂ during photosynthesis and release oxygen.', 'easy', 'science', 10),
  ('What is the fastest land animal?',
   '["Lion","Horse","Cheetah","Leopard"]', 2, 'The cheetah can reach speeds of up to 120 km/h (75 mph).', 'easy', 'science', 10),
  ('Which instrument has 88 keys?',
   '["Guitar","Violin","Piano","Harp"]', 2, 'A standard piano has 88 keys — 52 white and 36 black.', 'easy', 'music', 10);

-- MEDIUM (xp_value = 20)
INSERT INTO public.general_questions (question, options, correct_index, explanation, difficulty, category, xp_value) VALUES
  ('What is the square root of 169?',
   '["11","12","13","14"]', 2, '13 × 13 = 169.', 'medium', 'math', 20),
  ('Which element has the atomic number 79?',
   '["Silver","Gold","Platinum","Copper"]', 1, 'Gold (Au) has atomic number 79.', 'medium', 'science', 20),
  ('What year did the Berlin Wall fall?',
   '["1987","1989","1991","1993"]', 1, 'The Berlin Wall fell on November 9, 1989.', 'medium', 'history', 20),
  ('What is the capital of Australia?',
   '["Sydney","Melbourne","Brisbane","Canberra"]', 3, 'Canberra is the capital of Australia, chosen as a compromise between Sydney and Melbourne.', 'medium', 'geography', 20),
  ('Which Shakespeare play features the character Iago?',
   '["Hamlet","Macbeth","Othello","King Lear"]', 2, 'Iago is the villain in Shakespeare''s Othello.', 'medium', 'literature', 20),
  ('What is the speed of light in a vacuum (approx.)?',
   '["300,000 km/s","150,000 km/s","450,000 km/s","200,000 km/s"]', 0, 'The speed of light in vacuum is approximately 299,792 km/s, commonly rounded to 300,000 km/s.', 'medium', 'science', 20),
  ('Which country has the most natural lakes?',
   '["Russia","USA","Brazil","Canada"]', 3, 'Canada has over 2 million lakes — more than any other country.', 'medium', 'geography', 20),
  ('What does DNA stand for?',
   '["Deoxyribonucleic Acid","Deoxyribose Nucleic Acid","Dynamic Nucleic Assembly","Dinitrogen Acid"]', 0, 'DNA stands for Deoxyribonucleic Acid.', 'medium', 'science', 20),
  ('Who painted the Sistine Chapel ceiling?',
   '["Leonardo da Vinci","Raphael","Michelangelo","Caravaggio"]', 2, 'Michelangelo painted the Sistine Chapel ceiling between 1508 and 1512.', 'medium', 'art', 20),
  ('What is the currency of Japan?',
   '["Yuan","Won","Yen","Ringgit"]', 2, 'Japan''s currency is the Japanese Yen (¥).', 'medium', 'general', 20),
  ('In what year was the United Nations founded?',
   '["1944","1945","1946","1947"]', 1, 'The United Nations was founded on October 24, 1945.', 'medium', 'history', 20),
  ('Which planet has the most moons?',
   '["Jupiter","Saturn","Uranus","Neptune"]', 1, 'Saturn has the most confirmed moons — over 140 as of 2024.', 'medium', 'science', 20),
  ('What is the longest river in the world?',
   '["Amazon","Mississippi","Yangtze","Nile"]', 3, 'The Nile River in Africa is widely considered the longest at approximately 6,650 km.', 'medium', 'geography', 20),
  ('Which economist wrote "The Wealth of Nations"?',
   '["John Maynard Keynes","Karl Marx","Adam Smith","Milton Friedman"]', 2, 'Adam Smith published "The Wealth of Nations" in 1776.', 'medium', 'history', 20),
  ('What is the hardest natural substance on Earth?',
   '["Granite","Quartz","Diamond","Corundum"]', 2, 'Diamond rates 10 on the Mohs hardness scale — the highest possible.', 'medium', 'science', 20);

-- HARD (xp_value = 40)
INSERT INTO public.general_questions (question, options, correct_index, explanation, difficulty, category, xp_value) VALUES
  ('What is the Chandrasekhar limit?',
   '["1.0 solar masses","1.4 solar masses","2.0 solar masses","3.0 solar masses"]', 1, 'The Chandrasekhar limit (~1.4 M☉) is the maximum mass of a stable white dwarf star.', 'hard', 'science', 40),
  ('Who formulated the incompleteness theorems?',
   '["Bertrand Russell","David Hilbert","Kurt Gödel","Alan Turing"]', 2, 'Kurt Gödel published his incompleteness theorems in 1931.', 'hard', 'math', 40),
  ('In which year did the Ottoman Empire officially end?',
   '["1918","1920","1922","1924"]', 2, 'The Ottoman Empire was officially abolished on November 1, 1922, when the Grand National Assembly abolished the Sultanate.', 'hard', 'history', 40),
  ('What is the Coriolis effect caused by?',
   '["Moon''s gravity","Earth''s rotation","Solar wind","Magnetic field"]', 1, 'The Coriolis effect is an inertial force caused by Earth''s rotation, deflecting moving objects.', 'hard', 'science', 40),
  ('Which ancient library was considered the largest in the ancient world?',
   '["Library of Athens","Library of Alexandria","Library of Pergamum","Library of Babylon"]', 1, 'The Library of Alexandria in Egypt was the largest and most significant library of the ancient world.', 'hard', 'history', 40),
  ('What is the Heisenberg Uncertainty Principle about?',
   '["Light speed","Position and momentum","Energy and mass","Temperature and pressure"]', 1, 'The Uncertainty Principle states that the position and momentum of a particle cannot both be precisely known simultaneously.', 'hard', 'science', 40),
  ('What language family does Finnish belong to?',
   '["Indo-European","Semitic","Uralic","Turkic"]', 2, 'Finnish belongs to the Uralic language family, not Indo-European.', 'hard', 'language', 40),
  ('What is the name of the process by which rocks are broken down by physical and chemical agents?',
   '["Erosion","Sedimentation","Weathering","Deposition"]', 2, 'Weathering is the process of breaking down rocks and minerals through physical, chemical, and biological agents.', 'hard', 'science', 40),
  ('Who developed the theory of general relativity?',
   '["Isaac Newton","Niels Bohr","Albert Einstein","Max Planck"]', 2, 'Albert Einstein published the theory of general relativity in 1915.', 'hard', 'science', 40),
  ('What is the term for a word that reads the same forwards and backwards?',
   '["Anagram","Palindrome","Homophone","Oxymoron"]', 1, 'A palindrome reads the same forwards and backwards, e.g., "racecar".', 'hard', 'language', 40),
  ('In economics, what does "liquidity trap" describe?',
   '["High inflation","Zero interest rates where monetary policy is ineffective","Bank insolvency","Currency devaluation"]', 1, 'A liquidity trap occurs when interest rates are near zero and monetary policy becomes ineffective in stimulating the economy.', 'hard', 'economics', 40),
  ('What is the name of the deepest point in Earth''s oceans?',
   '["Puerto Rico Trench","Java Trench","Mariana Trench","Tonga Trench"]', 2, 'The Challenger Deep in the Mariana Trench is the deepest known point at ~11,034 meters.', 'hard', 'geography', 40),
  ('Who wrote "Thus Spoke Zarathustra"?',
   '["Immanuel Kant","Friedrich Nietzsche","Arthur Schopenhauer","Georg Hegel"]', 1, 'Friedrich Nietzsche wrote "Thus Spoke Zarathustra" between 1883 and 1885.', 'hard', 'philosophy', 40),
  ('What is the Baader-Meinhof phenomenon?',
   '["A type of optical illusion","The feeling that something recently learned appears everywhere","A memory disorder","A cognitive bias causing overconfidence"]', 1, 'The Baader-Meinhof phenomenon (frequency illusion) is when something you recently noticed suddenly appears everywhere.', 'hard', 'psychology', 40),
  ('What is the half-life of Carbon-14?',
   '["1,300 years","5,730 years","14,000 years","50,000 years"]', 1, 'Carbon-14 has a half-life of approximately 5,730 years, making it useful for radiocarbon dating.', 'hard', 'science', 40);
