-- =============================================================
-- NEXUS SEED DATA
-- Run: supabase db seed  OR paste into the Supabase SQL editor.
-- Articles are NOT seeded here — they come from the real news APIs.
-- Safe to re-run (all inserts use ON CONFLICT DO NOTHING).
-- =============================================================

BEGIN;

-- ── UUID constants (referenced throughout) ─────────────────────────────────
-- Users  : 1111…0001 – 1111…0015
-- Sources: 2222…0001 – 2222…0006
-- Journal: 3333…0001 – 3333…0012
-- Quizzes: 5555…0001 – 5555…0007
-- QQs    : 6666…0001 – 6666…0035
-- GQs    : 7777…0001 – 7777…0030
-- Clusters:8888…0001 – 8888…0005

-- ── 1. NEWS SOURCES ──────────────────────────────────────────────────────────
INSERT INTO public.news_sources (id, name, base_url, is_active, category) VALUES
  ('22222222-2222-2222-2222-000000000001', 'The Guardian',     'https://www.theguardian.com',       true, 'world'),
  ('22222222-2222-2222-2222-000000000002', 'BBC News',         'https://www.bbc.com/news',          true, 'world'),
  ('22222222-2222-2222-2222-000000000003', 'Reuters',          'https://www.reuters.com',           true, 'business'),
  ('22222222-2222-2222-2222-000000000004', 'Al Jazeera',       'https://www.aljazeera.com',         true, 'world'),
  ('22222222-2222-2222-2222-000000000005', 'GNews',            'https://gnews.io',                  true, 'technology'),
  ('22222222-2222-2222-2222-000000000006', 'Associated Press', 'https://apnews.com',                true, 'world')
ON CONFLICT (id) DO NOTHING;

-- ── 2. JOURNALISTS ────────────────────────────────────────────────────────────
INSERT INTO public.journalists (id, display_name, bio, outlet, article_count, byline_match, is_verified, follower_count) VALUES
  ('33333333-3333-3333-3333-000000000001', 'Emma Richardson',  'Senior foreign correspondent covering European politics and climate policy.', 'The Guardian',     142, 'Emma Richardson',  true,  8400),
  ('33333333-3333-3333-3333-000000000002', 'David Kaplan',     'Technology editor. Former software engineer, now explaining tech to everyone.',   'BBC News',         98,  'David Kaplan',     true,  5200),
  ('33333333-3333-3333-3333-000000000003', 'Layla Mansour',    'Middle East bureau chief based in Beirut. Award-winning war correspondent.',     'Reuters',          207, 'Layla Mansour',    true,  12300),
  ('33333333-3333-3333-3333-000000000004', 'Carlos Vega',      'Business and markets reporter. Covers Wall Street and emerging markets.',        'Reuters',          183, 'Carlos Vega',      true,  6700),
  ('33333333-3333-3333-3333-000000000005', 'Priya Nair',       'Health and science correspondent. PhD in molecular biology.',                    'The Guardian',     76,  'Priya Nair',       true,  4100),
  ('33333333-3333-3333-3333-000000000006', 'James Okafor',     'Sports journalist covering football, athletics and the Olympics.',               'BBC News',         134, 'James Okafor',     true,  9800),
  ('33333333-3333-3333-3333-000000000007', 'Sofia Andreou',    'Climate and environment editor. Author of "The Carbon Ledger".',                 'The Guardian',     89,  'Sofia Andreou',    true,  7300),
  ('33333333-3333-3333-3333-000000000008', 'Ahmed Khalid',     'Political analyst and commentator covering Arab world affairs.',                 'Al Jazeera',       165, 'Ahmed Khalid',     true,  11200),
  ('33333333-3333-3333-3333-000000000009', 'Mei Lin',          'Asia-Pacific correspondent based in Singapore.',                                 'Associated Press', 121, 'Mei Lin',          true,  5600),
  ('33333333-3333-3333-3333-000000000010', 'Tomas Bergström',  'Economy and finance reporter covering Nordic markets and EU policy.',            'Reuters',          94,  'Tomas Bergström',  false, 2900),
  ('33333333-3333-3333-3333-000000000011', 'Zara Osei',        'Culture and entertainment writer. Hosts The Arts Desk podcast.',                 'BBC News',         58,  'Zara Osei',        false, 3400),
  ('33333333-3333-3333-3333-000000000012', 'Omar Farhat',      'Lebanon-based investigative journalist. Covers politics and reconstruction.',    'Al Jazeera',       112, 'Omar Farhat',      true,  7800)
ON CONFLICT (id) DO NOTHING;

-- ── 3. USERS (public.users only — no auth.users counterpart needed for test data) ──
INSERT INTO public.users (id, email, display_name, avatar_url, role, status, auth_provider, created_at) VALUES
  ('11111111-1111-1111-1111-000000000001', 'alex.thompson@nexustest.dev',   'Alex Thompson',   'https://api.dicebear.com/7.x/avataaars/svg?seed=alex',    'admin', 'active', 'email',  now() - interval '120 days'),
  ('11111111-1111-1111-1111-000000000002', 'sarah.chen@nexustest.dev',      'Sarah Chen',      'https://api.dicebear.com/7.x/avataaars/svg?seed=sarah',   'user',  'active', 'google', now() - interval '95 days'),
  ('11111111-1111-1111-1111-000000000003', 'mo.alrashid@nexustest.dev',     'Mohammed Al-Rashid','https://api.dicebear.com/7.x/avataaars/svg?seed=mo',   'user',  'active', 'email',  now() - interval '88 days'),
  ('11111111-1111-1111-1111-000000000004', 'elena.petrov@nexustest.dev',    'Elena Petrov',    'https://api.dicebear.com/7.x/avataaars/svg?seed=elena',   'user',  'active', 'google', now() - interval '74 days'),
  ('11111111-1111-1111-1111-000000000005', 'james.obrien@nexustest.dev',    'James O''Brien',  'https://api.dicebear.com/7.x/avataaars/svg?seed=james',   'user',  'active', 'email',  now() - interval '61 days'),
  ('11111111-1111-1111-1111-000000000006', 'yuki.tanaka@nexustest.dev',     'Yuki Tanaka',     'https://api.dicebear.com/7.x/avataaars/svg?seed=yuki',    'user',  'active', 'google', now() - interval '55 days'),
  ('11111111-1111-1111-1111-000000000007', 'amara.diallo@nexustest.dev',    'Amara Diallo',    'https://api.dicebear.com/7.x/avataaars/svg?seed=amara',   'user',  'active', 'email',  now() - interval '49 days'),
  ('11111111-1111-1111-1111-000000000008', 'lucas.garcia@nexustest.dev',    'Lucas García',    'https://api.dicebear.com/7.x/avataaars/svg?seed=lucas',   'user',  'active', 'google', now() - interval '42 days'),
  ('11111111-1111-1111-1111-000000000009', 'fatima.hassan@nexustest.dev',   'Fatima Hassan',   'https://api.dicebear.com/7.x/avataaars/svg?seed=fatima',  'user',  'active', 'email',  now() - interval '38 days'),
  ('11111111-1111-1111-1111-000000000010', 'noah.williams@nexustest.dev',   'Noah Williams',   'https://api.dicebear.com/7.x/avataaars/svg?seed=noah',    'user',  'active', 'google', now() - interval '31 days'),
  ('11111111-1111-1111-1111-000000000011', 'sophie.dubois@nexustest.dev',   'Sophie Dubois',   'https://api.dicebear.com/7.x/avataaars/svg?seed=sophie',  'user',  'active', 'email',  now() - interval '25 days'),
  ('11111111-1111-1111-1111-000000000012', 'kai.anderson@nexustest.dev',    'Kai Anderson',    'https://api.dicebear.com/7.x/avataaars/svg?seed=kai',     'user',  'active', 'google', now() - interval '20 days'),
  ('11111111-1111-1111-1111-000000000013', 'priya.patel@nexustest.dev',     'Priya Patel',     'https://api.dicebear.com/7.x/avataaars/svg?seed=priya',   'user',  'active', 'email',  now() - interval '14 days'),
  ('11111111-1111-1111-1111-000000000014', 'marco.romano@nexustest.dev',    'Marco Romano',    'https://api.dicebear.com/7.x/avataaars/svg?seed=marco',   'user',  'active', 'google', now() - interval '8 days'),
  ('11111111-1111-1111-1111-000000000015', 'leila.khalil@nexustest.dev',    'Leila Khalil',    'https://api.dicebear.com/7.x/avataaars/svg?seed=leila',   'user',  'active', 'email',  now() - interval '3 days')
ON CONFLICT (id) DO NOTHING;

-- ── 4. USER PREFERENCES ───────────────────────────────────────────────────────
INSERT INTO public.user_preferences (user_id, topics, preferred_language, onboarding_complete, updated_at) VALUES
  ('11111111-1111-1111-1111-000000000001', ARRAY['world','technology','business'],           'en', true,  now() - interval '118 days'),
  ('11111111-1111-1111-1111-000000000002', ARRAY['technology','science','health'],            'en', true,  now() - interval '93 days'),
  ('11111111-1111-1111-1111-000000000003', ARRAY['world','lebanon','technology'],             'ar', true,  now() - interval '86 days'),
  ('11111111-1111-1111-1111-000000000004', ARRAY['world','business','entertainment'],         'en', true,  now() - interval '72 days'),
  ('11111111-1111-1111-1111-000000000005', ARRAY['sports','world','business'],                'en', true,  now() - interval '59 days'),
  ('11111111-1111-1111-1111-000000000006', ARRAY['technology','science','health'],            'en', true,  now() - interval '53 days'),
  ('11111111-1111-1111-1111-000000000007', ARRAY['world','health','science'],                 'en', true,  now() - interval '47 days'),
  ('11111111-1111-1111-1111-000000000008', ARRAY['sports','entertainment','business'],        'en', true,  now() - interval '40 days'),
  ('11111111-1111-1111-1111-000000000009', ARRAY['lebanon','world','health'],                 'ar', true,  now() - interval '36 days'),
  ('11111111-1111-1111-1111-000000000010', ARRAY['technology','business','world'],            'en', true,  now() - interval '29 days'),
  ('11111111-1111-1111-1111-000000000011', ARRAY['entertainment','health','science'],         'en', true,  now() - interval '23 days'),
  ('11111111-1111-1111-1111-000000000012', ARRAY['technology','sports','entertainment'],      'en', false, now() - interval '18 days'),
  ('11111111-1111-1111-1111-000000000013', ARRAY['world','business'],                         'en', false, now() - interval '12 days'),
  ('11111111-1111-1111-1111-000000000014', ARRAY['sports','entertainment'],                   'en', false, now() - interval '6 days'),
  ('11111111-1111-1111-1111-000000000015', ARRAY['world'],                                    'en', false, now() - interval '2 days')
ON CONFLICT (user_id) DO NOTHING;

-- ── 5. USER STATS (drives the leaderboard) ────────────────────────────────────
INSERT INTO public.user_stats (user_id, total_xp, current_streak, longest_streak, quizzes_completed, perfect_scores, articles_read, last_activity_date, updated_at) VALUES
  ('11111111-1111-1111-1111-000000000001', 5820, 14, 42, 89,  23, 412, CURRENT_DATE,             now() - interval '1 hour'),
  ('11111111-1111-1111-1111-000000000002', 4950, 21, 35, 76,  18, 338, CURRENT_DATE,             now() - interval '2 hours'),
  ('11111111-1111-1111-1111-000000000003', 4120, 7,  29, 63,  14, 291, CURRENT_DATE - 1,         now() - interval '1 day'),
  ('11111111-1111-1111-1111-000000000004', 3680, 9,  24, 57,  11, 254, CURRENT_DATE,             now() - interval '3 hours'),
  ('11111111-1111-1111-1111-000000000005', 3100, 4,  18, 48,  8,  207, CURRENT_DATE - 2,         now() - interval '2 days'),
  ('11111111-1111-1111-1111-000000000006', 2640, 12, 20, 41,  7,  178, CURRENT_DATE,             now() - interval '4 hours'),
  ('11111111-1111-1111-1111-000000000007', 2180, 3,  15, 35,  5,  149, CURRENT_DATE - 1,         now() - interval '1 day'),
  ('11111111-1111-1111-1111-000000000008', 1820, 6,  12, 28,  4,  122, CURRENT_DATE,             now() - interval '5 hours'),
  ('11111111-1111-1111-1111-000000000009', 1490, 2,  9,  23,  3,  98,  CURRENT_DATE - 3,         now() - interval '3 days'),
  ('11111111-1111-1111-1111-000000000010', 1180, 5,  8,  19,  2,  76,  CURRENT_DATE - 1,         now() - interval '1 day'),
  ('11111111-1111-1111-1111-000000000011', 870,  1,  5,  14,  1,  54,  CURRENT_DATE - 4,         now() - interval '4 days'),
  ('11111111-1111-1111-1111-000000000012', 620,  3,  4,  10,  0,  37,  CURRENT_DATE - 2,         now() - interval '2 days'),
  ('11111111-1111-1111-1111-000000000013', 390,  0,  2,  6,   0,  21,  CURRENT_DATE - 7,         now() - interval '7 days'),
  ('11111111-1111-1111-1111-000000000014', 210,  1,  1,  3,   0,  12,  CURRENT_DATE - 5,         now() - interval '5 days'),
  ('11111111-1111-1111-1111-000000000015', 80,   0,  0,  1,   0,  4,   CURRENT_DATE - 2,         now() - interval '2 days')
ON CONFLICT (user_id) DO NOTHING;

-- ── 6. SUBSCRIPTIONS (2 active premium users) ─────────────────────────────────
INSERT INTO public.subscriptions (id, user_id, plan, status, start_date, end_date, auto_renew) VALUES
  ('aaaa0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-000000000002', 'premium', 'active', now() - interval '60 days', now() + interval '305 days', true),
  ('aaaa0000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-000000000004', 'premium', 'active', now() - interval '10 days', now() + interval '20 days',  true)
ON CONFLICT (user_id) DO NOTHING;

-- ── 7. BADGES ─────────────────────────────────────────────────────────────────
INSERT INTO public.badges (id, user_id, badge_type, label, awarded_at) VALUES
  ('dddd0000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-000000000001', 'early_adopter',  'Early Adopter',    now() - interval '119 days'),
  ('dddd0000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-000000000001', 'streak_30',      '30-Day Streak',    now() - interval '90 days'),
  ('dddd0000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-000000000001', 'perfect_score',  'Perfect Score',    now() - interval '80 days'),
  ('dddd0000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-000000000001', 'top_reader',     'Top Reader',       now() - interval '50 days'),
  ('dddd0000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-000000000002', 'early_adopter',  'Early Adopter',    now() - interval '94 days'),
  ('dddd0000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-000000000002', 'streak_7',       '7-Day Streak',     now() - interval '88 days'),
  ('dddd0000-0000-0000-0000-000000000007', '11111111-1111-1111-1111-000000000002', 'perfect_score',  'Perfect Score',    now() - interval '70 days'),
  ('dddd0000-0000-0000-0000-000000000008', '11111111-1111-1111-1111-000000000003', 'early_adopter',  'Early Adopter',    now() - interval '87 days'),
  ('dddd0000-0000-0000-0000-000000000009', '11111111-1111-1111-1111-000000000003', 'streak_7',       '7-Day Streak',     now() - interval '60 days'),
  ('dddd0000-0000-0000-0000-000000000010', '11111111-1111-1111-1111-000000000004', 'streak_7',       '7-Day Streak',     now() - interval '68 days'),
  ('dddd0000-0000-0000-0000-000000000011', '11111111-1111-1111-1111-000000000005', 'first_quiz',     'First Quiz',       now() - interval '60 days'),
  ('dddd0000-0000-0000-0000-000000000012', '11111111-1111-1111-1111-000000000006', 'streak_7',       '7-Day Streak',     now() - interval '43 days'),
  ('dddd0000-0000-0000-0000-000000000013', '11111111-1111-1111-1111-000000000006', 'first_quiz',     'First Quiz',       now() - interval '54 days'),
  ('dddd0000-0000-0000-0000-000000000014', '11111111-1111-1111-1111-000000000007', 'first_quiz',     'First Quiz',       now() - interval '48 days'),
  ('dddd0000-0000-0000-0000-000000000015', '11111111-1111-1111-1111-000000000008', 'first_quiz',     'First Quiz',       now() - interval '41 days')
ON CONFLICT (id) DO NOTHING;

-- ── 8. DIGEST PREFS ───────────────────────────────────────────────────────────
INSERT INTO public.digest_prefs (user_id, delivery_time, email_enabled, cohort_key) VALUES
  ('11111111-1111-1111-1111-000000000002', 'morning',   true,  'en-morning'),
  ('11111111-1111-1111-1111-000000000004', 'evening',   true,  'en-evening'),
  ('11111111-1111-1111-1111-000000000001', 'morning',   false, 'en-morning')
ON CONFLICT (user_id) DO NOTHING;

-- ── 9. QUIZZES (today + 6 previous days, all published) ──────────────────────
INSERT INTO public.quizzes (id, quiz_date, scheduled_for, title, is_published, xp_reward, questions, total_participants) VALUES
  ('55555555-5555-5555-5555-000000000001', CURRENT_DATE - 6, CURRENT_DATE - 6, 'World Events: May 1',      true, 50, '[]'::jsonb, 34),
  ('55555555-5555-5555-5555-000000000002', CURRENT_DATE - 5, CURRENT_DATE - 5, 'Tech & Innovation',         true, 50, '[]'::jsonb, 41),
  ('55555555-5555-5555-5555-000000000003', CURRENT_DATE - 4, CURRENT_DATE - 4, 'Global Business Pulse',     true, 50, '[]'::jsonb, 28),
  ('55555555-5555-5555-5555-000000000004', CURRENT_DATE - 3, CURRENT_DATE - 3, 'Science & Discovery',       true, 60, '[]'::jsonb, 37),
  ('55555555-5555-5555-5555-000000000005', CURRENT_DATE - 2, CURRENT_DATE - 2, 'Sports Roundup',            true, 50, '[]'::jsonb, 52),
  ('55555555-5555-5555-5555-000000000006', CURRENT_DATE - 1, CURRENT_DATE - 1, 'Health & Society',          true, 55, '[]'::jsonb, 48),
  ('55555555-5555-5555-5555-000000000007', CURRENT_DATE,     CURRENT_DATE,     'Today''s News Challenge',    true, 60, '[]'::jsonb, 19)
ON CONFLICT (quiz_date) DO NOTHING;

-- ── 10. QUIZ QUESTIONS (5 per quiz) ───────────────────────────────────────────
INSERT INTO public.quiz_questions (id, quiz_id, question, options, correct_index, explanation, time_limit, position) VALUES

-- Quiz 1 (May 1 — World Events)
('66666666-6666-6666-6666-000000000001','55555555-5555-5555-5555-000000000001',
 'Which body called an emergency session over escalating Middle East tensions in early May 2026?',
 '["UN Security Council","NATO","G7","ASEAN"]'::jsonb, 0,
 'The UN Security Council convened an emergency session to address the latest escalation.', 20, 0),
('66666666-6666-6666-6666-000000000002','55555555-5555-5555-5555-000000000001',
 'Brazil announced that Amazon deforestation had hit its lowest level in how many years?',
 '["2 years","3 years","5 years","10 years"]'::jsonb, 2,
 'Brazil celebrated a five-year low in deforestation rates, attributed to new enforcement policies.', 20, 1),
('66666666-6666-6666-6666-000000000003','55555555-5555-5555-5555-000000000001',
 'Which alliance announced an expanded military presence in Eastern Europe?',
 '["SCO","CSTO","NATO","AUKUS"]'::jsonb, 2,
 'NATO expanded its eastern flank deployments following an updated security review.', 20, 2),
('66666666-6666-6666-6666-000000000004','55555555-5555-5555-5555-000000000001',
 'G7 nations pledged how much in funding for African infrastructure in 2026?',
 '["$20 billion","$35 billion","$50 billion","$75 billion"]'::jsonb, 2,
 'The G7 committed $50 billion over five years to African infrastructure development.', 25, 3),
('66666666-6666-6666-6666-000000000005','55555555-5555-5555-5555-000000000001',
 'Which organisation declared a new health emergency over a respiratory virus outbreak?',
 '["CDC","ECDC","WHO","MSF"]'::jsonb, 2,
 'The WHO issued a public health emergency of international concern for the new respiratory virus.', 20, 4),

-- Quiz 2 (Tech & Innovation)
('66666666-6666-6666-6666-000000000006','55555555-5555-5555-5555-000000000002',
 'Which company released GPT-5 with advanced reasoning capabilities in 2026?',
 '["Google","Anthropic","OpenAI","Meta"]'::jsonb, 2,
 'OpenAI released GPT-5, showcasing significant improvements in multi-step reasoning tasks.', 20, 0),
('66666666-6666-6666-6666-000000000007','55555555-5555-5555-5555-000000000002',
 'The EU AI Act primarily affects companies with what characteristic?',
 '["EU headquarters","More than 1000 employees","High-risk AI systems","Annual AI revenue over €10m"]'::jsonb, 2,
 'The EU AI Act targets high-risk AI systems regardless of where the company is based.', 25, 1),
('66666666-6666-6666-6666-000000000008','55555555-5555-5555-5555-000000000002',
 'Which smartphone company unveiled Vision Pro updates with a major app ecosystem expansion?',
 '["Samsung","Google","Apple","Microsoft"]'::jsonb, 2,
 'Apple expanded Vision Pro''s developer ecosystem with new spatial computing APIs.', 20, 2),
('66666666-6666-6666-6666-000000000009','55555555-5555-5555-5555-000000000002',
 'TSMC''s capacity expansion is primarily located in which country?',
 '["South Korea","Japan","USA","Taiwan"]'::jsonb, 3,
 'TSMC continues to expand its primary manufacturing base in Taiwan.', 20, 3),
('66666666-6666-6666-6666-000000000010','55555555-5555-5555-5555-000000000002',
 'What efficiency record did researchers achieve with a new solar cell design?',
 '["38%","42%","47%","51%"]'::jsonb, 2,
 'A research team broke the 47% efficiency barrier for multi-junction solar cells.', 25, 4),

-- Quiz 3 (Business)
('66666666-6666-6666-6666-000000000011','55555555-5555-5555-5555-000000000003',
 'What did the Federal Reserve signal alongside its decision to hold rates steady?',
 '["Three rate hikes","No changes","Two rate cuts","Quantitative tightening"]'::jsonb, 2,
 'The Fed held rates but signalled two quarter-point cuts before year end.', 20, 0),
('66666666-6666-6666-6666-000000000012','55555555-5555-5555-5555-000000000003',
 'Oil prices surged roughly 8% after which organisation announced a production cut?',
 '["IEA","OPEC+","G7","US EIA"]'::jsonb, 1,
 'OPEC+ members agreed to reduce output, triggering an immediate price spike.', 20, 1),
('66666666-6666-6666-6666-000000000013','55555555-5555-5555-5555-000000000003',
 'xAI, Elon Musk''s AI company, reached what valuation after its latest funding round?',
 '["$40 billion","$60 billion","$80 billion","$100 billion"]'::jsonb, 2,
 'xAI closed a funding round valuing the company at $80 billion.', 25, 2),
('66666666-6666-6666-6666-000000000014','55555555-5555-5555-5555-000000000003',
 'How many new subscribers did Netflix report in Q1 2026?',
 '["8 million","14 million","20 million","27 million"]'::jsonb, 2,
 'Netflix added 20 million subscribers in Q1 2026, beating analyst forecasts.', 20, 3),
('66666666-6666-6666-6666-000000000015','55555555-5555-5555-5555-000000000003',
 'What was the IMF''s revised global GDP growth forecast for 2026?',
 '["2.8%","3.1%","3.4%","3.9%"]'::jsonb, 2,
 'The IMF revised its 2026 global growth forecast upward to 3.4%, citing resilient emerging markets.', 25, 4),

-- Quiz 4 (Science & Discovery)
('66666666-6666-6666-6666-000000000016','55555555-5555-5555-5555-000000000004',
 'NASA''s Artemis III mission was significant because it was the first crewed Moon landing since which year?',
 '["1969","1972","1979","1984"]'::jsonb, 1,
 'Artemis III returned astronauts to the lunar surface for the first time since Apollo 17 in 1972.', 20, 0),
('66666666-6666-6666-6666-000000000017','55555555-5555-5555-5555-000000000004',
 'Researchers used AI to discover new antibiotics by scanning what type of data?',
 '["Clinical trial records","Bacterial genomes","Patient health records","Protein databases"]'::jsonb, 1,
 'Machine learning models scanned billions of bacterial genome sequences to identify novel antibiotic candidates.', 25, 1),
('66666666-6666-6666-6666-000000000018','55555555-5555-5555-5555-000000000004',
 'A new gene therapy cured deafness in a clinical trial with what success rate?',
 '["72%","84%","94%","99%"]'::jsonb, 2,
 'The trial achieved a 94% success rate, restoring functional hearing in patients with a specific genetic mutation.', 20, 2),
('66666666-6666-6666-6666-000000000019','55555555-5555-5555-5555-000000000004',
 'CERN physicists detected possible evidence of which physical phenomenon?',
 '["Dark energy","Fifth fundamental force","Magnetic monopole","Higgs decay"]'::jsonb, 1,
 'An anomaly in particle collision data at CERN hinted at interactions beyond the Standard Model.', 25, 3),
('66666666-6666-6666-6666-000000000020','55555555-5555-5555-5555-000000000004',
 'A deep sea expedition found approximately how many new species in a Pacific trench?',
 '["50","120","200","350"]'::jsonb, 2,
 'Scientists catalogued around 200 previously unknown species during a record-depth Pacific expedition.', 20, 4),

-- Quiz 5 (Sports)
('66666666-6666-6666-6666-000000000021','55555555-5555-5555-5555-000000000005',
 'Which driver won their first race for Ferrari at the Monaco Grand Prix?',
 '["Carlos Sainz","Charles Leclerc","Lewis Hamilton","Max Verstappen"]'::jsonb, 2,
 'Lewis Hamilton converted his Ferrari debut win in the most prestigious race on the calendar.', 20, 0),
('66666666-6666-6666-6666-000000000022','55555555-5555-5555-5555-000000000005',
 'Argentina claimed its third consecutive Copa América trophy. Who scored the winning goal?',
 '["Messi","De Paul","Álvarez","Fernández"]'::jsonb, 0,
 'Lionel Messi netted the decisive penalty to secure Argentina''s historic third straight Copa América.', 25, 1),
('66666666-6666-6666-6666-000000000023','55555555-5555-5555-5555-000000000005',
 'How many applications were received when FIFA opened 2026 World Cup ticket sales?',
 '["2 million","5 million","10 million","15 million"]'::jsonb, 2,
 'FIFA received over 10 million ticket applications in the first 48 hours of sales.', 20, 2),
('66666666-6666-6666-6666-000000000024','55555555-5555-5555-5555-000000000005',
 'The ICC Champions Trophy final between India and Australia reportedly drew how many viewers?',
 '["150 million","250 million","400 million","600 million"]'::jsonb, 2,
 'The final attracted approximately 400 million viewers globally, setting a new cricket broadcasting record.', 20, 3),
('66666666-6666-6666-6666-000000000025','55555555-5555-5555-5555-000000000005',
 'Manchester City''s 2025-26 Premier League title was their how-manyth consecutive?',
 '["Fourth","Fifth","Sixth","Seventh"]'::jsonb, 2,
 'City clinched a sixth consecutive Premier League title under Pep Guardiola''s management.', 20, 4),

-- Quiz 6 (Health & Society)
('66666666-6666-6666-6666-000000000026','55555555-5555-5555-5555-000000000006',
 'What efficacy rate did an mRNA cancer vaccine show in melanoma trials?',
 '["55%","68%","80%","91%"]'::jsonb, 2,
 'The personalised mRNA vaccine developed by Moderna showed an 80% reduction in recurrence in late-stage trials.', 20, 0),
('66666666-6666-6666-6666-000000000027','55555555-5555-5555-5555-000000000006',
 'The global obesity rate reached approximately what percentage of adults in 2026?',
 '["28%","34%","40%","47%"]'::jsonb, 2,
 'WHO data placed global adult obesity at 40%, a record that is straining healthcare systems worldwide.', 20, 1),
('66666666-6666-6666-6666-000000000028','55555555-5555-5555-5555-000000000006',
 'A new blood test can detect how many types of cancer from a single sample?',
 '["12","30","50","72"]'::jsonb, 2,
 'The liquid biopsy test analyses cell-free DNA patterns to identify up to 50 cancer types.', 25, 2),
('66666666-6666-6666-6666-000000000029','55555555-5555-5555-5555-000000000006',
 'Following a Mediterranean diet is associated with what percentage lower risk of heart disease?',
 '["15%","25%","35%","45%"]'::jsonb, 2,
 'A large-scale study confirmed a 35% reduction in cardiovascular events among adherents of the Mediterranean diet.', 20, 3),
('66666666-6666-6666-6666-000000000030','55555555-5555-5555-5555-000000000006',
 'The FDA approved the first OTC version of which life-saving medication?',
 '["Epinephrine","Insulin","Naloxone","Aspirin"]'::jsonb, 2,
 'Naloxone nasal spray became available without a prescription to help combat the opioid crisis.', 20, 4),

-- Quiz 7 (Today's Challenge)
('66666666-6666-6666-6666-000000000031','55555555-5555-5555-5555-000000000007',
 'Which Lebanese film won the Palme d''Or at the 2026 Cannes Film Festival?',
 '["Beirut Blues","The Cedar Promise","Beirut Nocturne","Shadows of June"]'::jsonb, 2,
 '"Beirut Nocturne" by director Nadia Farhat became the first Lebanese film to win the Palme d''Or.', 20, 0),
('66666666-6666-6666-6666-000000000032','55555555-5555-5555-5555-000000000007',
 'Which streaming platform reached 300 million subscribers after a pricing restructure?',
 '["Netflix","HBO Max","Amazon Prime","Disney+"]'::jsonb, 3,
 'Disney+ crossed 300 million subscribers following a bundled pricing strategy.', 20, 1),
('66666666-6666-6666-6666-000000000033','55555555-5555-5555-5555-000000000007',
 'What opening weekend box office did Marvel''s "Avengers: New Dawn" achieve domestically?',
 '["$180 million","$215 million","$250 million","$310 million"]'::jsonb, 2,
 'The film broke domestic opening weekend records with a $250 million debut.', 20, 2),
('66666666-6666-6666-6666-000000000034','55555555-5555-5555-5555-000000000007',
 'Lebanon secured a deal with which neighbouring country over maritime border demarcation?',
 '["Cyprus","Syria","Israel","Jordan"]'::jsonb, 2,
 'Lebanon and Israel finalised a maritime boundary agreement, opening offshore areas for energy exploration.', 25, 3),
('66666666-6666-6666-6666-000000000035','55555555-5555-5555-5555-000000000007',
 'How much venture capital did Beirut startups attract according to the 2026 Arab VC report?',
 '["$50 million","$120 million","$200 million","$350 million"]'::jsonb, 2,
 'Beirut''s resilient tech ecosystem attracted $200 million in Arab venture capital despite ongoing challenges.', 25, 4)

ON CONFLICT (id) DO NOTHING;

-- ── 11. GENERAL KNOWLEDGE QUESTIONS ──────────────────────────────────────────

-- Easy (10)
INSERT INTO public.general_questions (question, options, correct_index, explanation, difficulty, category, xp_value) VALUES
('What is the capital of France?',
 '["Berlin","Madrid","Paris","Rome"]'::jsonb, 2,
 'Paris has been the capital of France since the 10th century.', 'easy', 'geography', 10),

('Which planet is closest to the Sun?',
 '["Venus","Earth","Mercury","Mars"]'::jsonb, 2,
 'Mercury orbits closest to the Sun at an average distance of 57.9 million km.', 'easy', 'science', 10),

('How many sides does a hexagon have?',
 '["5","6","7","8"]'::jsonb, 1,
 'A hexagon has six sides and six angles.', 'easy', 'mathematics', 10),

('Which ocean is the largest in the world?',
 '["Atlantic","Indian","Arctic","Pacific"]'::jsonb, 3,
 'The Pacific Ocean covers more than 165 million square kilometres.', 'easy', 'geography', 10),

('What language has the most native speakers worldwide?',
 '["English","Spanish","Mandarin Chinese","Hindi"]'::jsonb, 2,
 'Mandarin Chinese has roughly 920 million native speakers.', 'easy', 'language', 10),

('In which year did the First World War begin?',
 '["1910","1912","1914","1916"]'::jsonb, 2,
 'World War I began on 28 July 1914 following the assassination of Archduke Franz Ferdinand.', 'easy', 'history', 10),

('What is the chemical symbol for water?',
 '["HO","H2O","OH2","H3O"]'::jsonb, 1,
 'Water is composed of two hydrogen atoms and one oxygen atom, hence H₂O.', 'easy', 'science', 10),

('Which continent is Brazil located on?',
 '["North America","Africa","Asia","South America"]'::jsonb, 3,
 'Brazil is the largest country in South America, covering about 47% of the continent.', 'easy', 'geography', 10),

('What is the hardest natural substance on Earth?',
 '["Platinum","Quartz","Diamond","Titanium"]'::jsonb, 2,
 'Diamond scores 10 on the Mohs hardness scale — the maximum.', 'easy', 'science', 10),

('How many stripes are on the United States flag?',
 '["12","13","14","15"]'::jsonb, 1,
 'The 13 stripes represent the original 13 colonies.', 'easy', 'history', 10);

-- Medium (10)
INSERT INTO public.general_questions (question, options, correct_index, explanation, difficulty, category, xp_value) VALUES
('What does "GDP" stand for?',
 '["Gross Domestic Product","General Development Plan","Gross Demand Production","Government Debt Policy"]'::jsonb, 0,
 'GDP measures the total monetary value of all goods and services produced within a country.', 'medium', 'economics', 15),

('Which country launched the world''s first artificial satellite, Sputnik 1?',
 '["USA","China","Germany","Soviet Union"]'::jsonb, 3,
 'The Soviet Union launched Sputnik 1 on 4 October 1957, beginning the Space Age.', 'medium', 'history', 15),

('What is the speed of light in a vacuum (approximately)?',
 '["150,000 km/s","300,000 km/s","450,000 km/s","600,000 km/s"]'::jsonb, 1,
 'Light travels at approximately 299,792 km/s in a vacuum.', 'medium', 'science', 15),

('Which ancient wonder of the world still stands today?',
 '["Hanging Gardens of Babylon","Colossus of Rhodes","Great Pyramid of Giza","Lighthouse of Alexandria"]'::jsonb, 2,
 'The Great Pyramid of Giza is the only ancient wonder still largely intact.', 'medium', 'history', 15),

('In programming, what does "API" stand for?',
 '["Automated Program Interface","Application Programming Interface","Advanced Protocol Integration","Automated Processing Interface"]'::jsonb, 1,
 'An API defines rules for how different software components communicate.', 'medium', 'technology', 15),

('Which gas makes up the majority of Earth''s atmosphere?',
 '["Oxygen","Carbon dioxide","Argon","Nitrogen"]'::jsonb, 3,
 'Nitrogen constitutes about 78% of the atmosphere, followed by oxygen at 21%.', 'medium', 'science', 15),

('The Silk Road historically connected China to which region?',
 '["Sub-Saharan Africa","The Americas","Mediterranean Europe","Scandinavia"]'::jsonb, 2,
 'The Silk Road linked East Asia to the Mediterranean, facilitating trade and cultural exchange.', 'medium', 'history', 15),

('What is the term for a government spending more than it collects in tax?',
 '["Trade surplus","Budget deficit","Inflation","Stagflation"]'::jsonb, 1,
 'A budget deficit occurs when government expenditure exceeds revenue in a fiscal period.', 'medium', 'economics', 15),

('Which ocean current moderates the climate of Western Europe?',
 '["Labrador Current","Kuroshio Current","Gulf Stream","California Current"]'::jsonb, 2,
 'The Gulf Stream transports warm water from the Gulf of Mexico to the North Atlantic.', 'medium', 'geography', 15),

('What is the base unit of electric current in the SI system?',
 '["Volt","Watt","Ohm","Ampere"]'::jsonb, 3,
 'The ampere (A) is one of the seven base SI units, measuring electric current.', 'medium', 'science', 15);

-- Hard (10)
INSERT INTO public.general_questions (question, options, correct_index, explanation, difficulty, category, xp_value) VALUES
('What is the name of the principle that states the position and momentum of a particle cannot both be known precisely?',
 '["Pauli Exclusion Principle","Uncertainty Principle","Superposition Principle","Complementarity Principle"]'::jsonb, 1,
 'Heisenberg''s Uncertainty Principle (1927) sets fundamental limits on precision in quantum mechanics.', 'hard', 'science', 20),

('The Treaty of Westphalia (1648) ended which conflict?',
 '["The Hundred Years'' War","The Thirty Years'' War","The Seven Years'' War","The War of the Spanish Succession"]'::jsonb, 1,
 'The Peace of Westphalia ended the Thirty Years'' War and established the concept of state sovereignty.', 'hard', 'history', 20),

('Which economic concept describes the cost of the next best alternative forgone?',
 '["Sunk cost","Marginal cost","Opportunity cost","Externality"]'::jsonb, 2,
 'Opportunity cost is a foundational concept in economics representing the value of the best unchosen option.', 'hard', 'economics', 20),

('In computer science, what does "Big O notation" primarily describe?',
 '["Memory allocation","Algorithm time complexity","Network bandwidth","Database indexing"]'::jsonb, 1,
 'Big O notation expresses the worst-case growth rate of an algorithm''s runtime relative to input size.', 'hard', 'technology', 20),

('The Coriolis effect influences atmospheric circulation because of what property of Earth?',
 '["Its magnetic field","Its axial tilt","Its rotation","Its elliptical orbit"]'::jsonb, 2,
 'Earth''s rotation causes moving air and water to deflect right in the Northern Hemisphere and left in the Southern.', 'hard', 'science', 20),

('Which philosopher argued that knowledge comes solely from sensory experience (empiricism)?',
 '["René Descartes","Immanuel Kant","John Locke","Baruch Spinoza"]'::jsonb, 2,
 'John Locke proposed that the mind is a tabula rasa, with all knowledge derived from experience.', 'hard', 'philosophy', 20),

('What is the approximate half-life of Carbon-14, used in radiocarbon dating?',
 '["1,800 years","5,730 years","12,000 years","22,000 years"]'::jsonb, 1,
 'Carbon-14 decays at a known rate with a half-life of 5,730 years, allowing age estimation of organic material.', 'hard', 'science', 20),

('Mercator projection maps distort which geographical feature at high latitudes?',
 '["Coastline shape","Country colours","Land area size","Ocean depth"]'::jsonb, 2,
 'Mercator maps preserve shape but inflate the apparent size of landmasses near the poles (e.g. Greenland vs Africa).', 'hard', 'geography', 20),

('In international law, what is "jus cogens"?',
 '["The right to declare war","Peremptory norms that no state can derogate","The law of the sea","Diplomatic immunity rules"]'::jsonb, 1,
 'Jus cogens norms (e.g. prohibition of genocide) are absolute in international law and override treaties.', 'hard', 'law', 20),

('Which theorem states that any planar map can be coloured with at most four colours so no adjacent regions share a colour?',
 '["Euler''s theorem","Four Colour Theorem","Jordan Curve Theorem","Brouwer Fixed Point Theorem"]'::jsonb, 1,
 'The Four Colour Theorem was proven in 1976 by Appel and Haken, the first major theorem proved with computer assistance.', 'hard', 'mathematics', 20);

-- ── 12. CLUSTERS ─────────────────────────────────────────────────────────────
INSERT INTO public.clusters (id, name, headline, source_count) VALUES
  ('88888888-8888-8888-8888-000000000001', 'Middle East Crisis',      'Escalating regional tensions spark emergency UN meeting', 4),
  ('88888888-8888-8888-8888-000000000002', 'AI Regulation Wave',      'Global regulators move to govern AI after landmark EU Act', 5),
  ('88888888-8888-8888-8888-000000000003', 'Lebanon Recovery',        'Donors release funds as Beirut reconstruction finally begins', 3),
  ('88888888-8888-8888-8888-000000000004', 'Global Obesity Crisis',   'WHO warns health systems unprepared as obesity rate hits 40%', 4),
  ('88888888-8888-8888-8888-000000000005', '2026 World Cup Fever',    'Record ticket demand signals biggest World Cup in history', 3)
ON CONFLICT (id) DO NOTHING;

-- ── 13. ANALYTICS (last 30 days) ─────────────────────────────────────────────
INSERT INTO public.analytics_daily (date, active_users, api_calls_used, top_countries, top_categories) VALUES
  (CURRENT_DATE - 29, 12,  28,  '[{"code":"US","count":5},{"code":"LB","count":3},{"code":"GB","count":2}]'::jsonb, '[{"cat":"world","count":10},{"cat":"technology","count":7}]'::jsonb),
  (CURRENT_DATE - 28, 15,  34,  '[{"code":"US","count":6},{"code":"LB","count":4},{"code":"DE","count":2}]'::jsonb, '[{"cat":"world","count":12},{"cat":"technology","count":8}]'::jsonb),
  (CURRENT_DATE - 27, 18,  41,  '[{"code":"US","count":7},{"code":"LB","count":4},{"code":"GB","count":3}]'::jsonb, '[{"cat":"technology","count":13},{"cat":"world","count":10}]'::jsonb),
  (CURRENT_DATE - 26, 14,  32,  '[{"code":"US","count":6},{"code":"LB","count":3},{"code":"FR","count":2}]'::jsonb, '[{"cat":"world","count":9},{"cat":"business","count":7}]'::jsonb),
  (CURRENT_DATE - 25, 21,  49,  '[{"code":"US","count":9},{"code":"LB","count":5},{"code":"GB","count":3}]'::jsonb, '[{"cat":"world","count":15},{"cat":"technology","count":11}]'::jsonb),
  (CURRENT_DATE - 24, 19,  44,  '[{"code":"US","count":8},{"code":"LB","count":4},{"code":"DE","count":3}]'::jsonb, '[{"cat":"technology","count":14},{"cat":"world","count":12}]'::jsonb),
  (CURRENT_DATE - 23, 25,  58,  '[{"code":"US","count":10},{"code":"LB","count":6},{"code":"GB","count":4}]'::jsonb, '[{"cat":"world","count":18},{"cat":"sports","count":10}]'::jsonb),
  (CURRENT_DATE - 22, 23,  53,  '[{"code":"US","count":9},{"code":"LB","count":5},{"code":"FR","count":4}]'::jsonb, '[{"cat":"world","count":16},{"cat":"technology","count":12}]'::jsonb),
  (CURRENT_DATE - 21, 28,  64,  '[{"code":"US","count":11},{"code":"LB","count":7},{"code":"GB","count":5}]'::jsonb, '[{"cat":"world","count":20},{"cat":"technology","count":14}]'::jsonb),
  (CURRENT_DATE - 20, 31,  71,  '[{"code":"US","count":13},{"code":"LB","count":7},{"code":"DE","count":5}]'::jsonb, '[{"cat":"technology","count":18},{"cat":"world","count":16}]'::jsonb),
  (CURRENT_DATE - 19, 27,  62,  '[{"code":"US","count":11},{"code":"LB","count":6},{"code":"GB","count":5}]'::jsonb, '[{"cat":"world","count":18},{"cat":"business","count":12}]'::jsonb),
  (CURRENT_DATE - 18, 29,  67,  '[{"code":"US","count":12},{"code":"LB","count":7},{"code":"FR","count":4}]'::jsonb, '[{"cat":"world","count":19},{"cat":"technology","count":15}]'::jsonb),
  (CURRENT_DATE - 17, 33,  76,  '[{"code":"US","count":13},{"code":"LB","count":8},{"code":"GB","count":5}]'::jsonb, '[{"cat":"technology","count":21},{"cat":"world","count":17}]'::jsonb),
  (CURRENT_DATE - 16, 35,  81,  '[{"code":"US","count":14},{"code":"LB","count":8},{"code":"DE","count":6}]'::jsonb, '[{"cat":"world","count":22},{"cat":"technology","count":18}]'::jsonb),
  (CURRENT_DATE - 15, 38,  87,  '[{"code":"US","count":15},{"code":"LB","count":9},{"code":"GB","count":6}]'::jsonb, '[{"cat":"world","count":24},{"cat":"technology","count":19}]'::jsonb),
  (CURRENT_DATE - 14, 41,  94,  '[{"code":"US","count":16},{"code":"LB","count":10},{"code":"FR","count":6}]'::jsonb, '[{"cat":"technology","count":25},{"cat":"world","count":20}]'::jsonb),
  (CURRENT_DATE - 13, 36,  83,  '[{"code":"US","count":14},{"code":"LB","count":9},{"code":"DE","count":6}]'::jsonb, '[{"cat":"world","count":22},{"cat":"sports","count":14}]'::jsonb),
  (CURRENT_DATE - 12, 44,  101, '[{"code":"US","count":17},{"code":"LB","count":11},{"code":"GB","count":7}]'::jsonb, '[{"cat":"world","count":26},{"cat":"technology","count":21}]'::jsonb),
  (CURRENT_DATE - 11, 47,  108, '[{"code":"US","count":18},{"code":"LB","count":12},{"code":"FR","count":8}]'::jsonb, '[{"cat":"technology","count":28},{"cat":"world","count":23}]'::jsonb),
  (CURRENT_DATE - 10, 52,  119, '[{"code":"US","count":20},{"code":"LB","count":13},{"code":"GB","count":8}]'::jsonb, '[{"cat":"world","count":30},{"cat":"technology","count":24}]'::jsonb),
  (CURRENT_DATE - 9,  49,  113, '[{"code":"US","count":19},{"code":"LB","count":12},{"code":"DE","count":8}]'::jsonb, '[{"cat":"technology","count":26},{"cat":"world","count":24}]'::jsonb),
  (CURRENT_DATE - 8,  55,  126, '[{"code":"US","count":21},{"code":"LB","count":14},{"code":"GB","count":9}]'::jsonb, '[{"cat":"world","count":33},{"cat":"technology","count":27}]'::jsonb),
  (CURRENT_DATE - 7,  58,  133, '[{"code":"US","count":22},{"code":"LB","count":15},{"code":"FR","count":9}]'::jsonb, '[{"cat":"world","count":35},{"cat":"technology","count":28}]'::jsonb),
  (CURRENT_DATE - 6,  61,  140, '[{"code":"US","count":23},{"code":"LB","count":16},{"code":"DE","count":10}]'::jsonb,'[{"cat":"technology","count":30},{"cat":"world","count":29}]'::jsonb),
  (CURRENT_DATE - 5,  65,  149, '[{"code":"US","count":25},{"code":"LB","count":17},{"code":"GB","count":10}]'::jsonb,'[{"cat":"world","count":38},{"cat":"technology","count":31}]'::jsonb),
  (CURRENT_DATE - 4,  69,  158, '[{"code":"US","count":26},{"code":"LB","count":18},{"code":"FR","count":11}]'::jsonb,'[{"cat":"technology","count":33},{"cat":"world","count":32}]'::jsonb),
  (CURRENT_DATE - 3,  72,  165, '[{"code":"US","count":27},{"code":"LB","count":19},{"code":"GB","count":11}]'::jsonb,'[{"cat":"world","count":41},{"cat":"technology","count":34}]'::jsonb),
  (CURRENT_DATE - 2,  78,  179, '[{"code":"US","count":30},{"code":"LB","count":20},{"code":"DE","count":12}]'::jsonb,'[{"cat":"world","count":44},{"cat":"technology","count":36}]'::jsonb),
  (CURRENT_DATE - 1,  83,  190, '[{"code":"US","count":32},{"code":"LB","count":21},{"code":"GB","count":13}]'::jsonb,'[{"cat":"technology","count":38},{"cat":"world","count":40}]'::jsonb),
  (CURRENT_DATE,      88,  202, '[{"code":"US","count":34},{"code":"LB","count":22},{"code":"FR","count":14}]'::jsonb,'[{"cat":"world","count":47},{"cat":"technology","count":40}]'::jsonb)
ON CONFLICT (date) DO NOTHING;

-- ── 14. QUIZ RESULTS (historic completions by seeded users) ──────────────────
-- Only insert for quizzes that are past days (not today, to keep today fresh for testing)
INSERT INTO public.quiz_results (id, user_id, quiz_id, score, xp_earned, answers, streak_day, completed_at) VALUES
  ('eeee0000-0000-0000-0000-000000000001','11111111-1111-1111-1111-000000000001','55555555-5555-5555-5555-000000000001', 5, 50, '{0,2,2,2,2}', 6, (CURRENT_DATE - 6)::timestamptz + interval '9 hours'),
  ('eeee0000-0000-0000-0000-000000000002','11111111-1111-1111-1111-000000000001','55555555-5555-5555-5555-000000000002', 5, 50, '{2,2,2,3,2}', 7, (CURRENT_DATE - 5)::timestamptz + interval '9 hours'),
  ('eeee0000-0000-0000-0000-000000000003','11111111-1111-1111-1111-000000000001','55555555-5555-5555-5555-000000000003', 4, 40, '{2,1,2,2,2}', 8, (CURRENT_DATE - 4)::timestamptz + interval '9 hours'),
  ('eeee0000-0000-0000-0000-000000000004','11111111-1111-1111-1111-000000000001','55555555-5555-5555-5555-000000000004', 5, 60, '{1,1,2,1,2}', 9, (CURRENT_DATE - 3)::timestamptz + interval '9 hours'),
  ('eeee0000-0000-0000-0000-000000000005','11111111-1111-1111-1111-000000000001','55555555-5555-5555-5555-000000000005', 5, 50, '{2,0,2,2,2}',10, (CURRENT_DATE - 2)::timestamptz + interval '9 hours'),
  ('eeee0000-0000-0000-0000-000000000006','11111111-1111-1111-1111-000000000001','55555555-5555-5555-5555-000000000006', 5, 55, '{2,2,2,2,2}',11, (CURRENT_DATE - 1)::timestamptz + interval '9 hours'),
  ('eeee0000-0000-0000-0000-000000000007','11111111-1111-1111-1111-000000000002','55555555-5555-5555-5555-000000000001', 4, 40, '{0,2,0,2,2}', 5, (CURRENT_DATE - 6)::timestamptz + interval '10 hours'),
  ('eeee0000-0000-0000-0000-000000000008','11111111-1111-1111-1111-000000000002','55555555-5555-5555-5555-000000000002', 5, 50, '{2,2,2,3,2}', 6, (CURRENT_DATE - 5)::timestamptz + interval '10 hours'),
  ('eeee0000-0000-0000-0000-000000000009','11111111-1111-1111-1111-000000000002','55555555-5555-5555-5555-000000000004', 5, 60, '{1,1,2,1,2}', 7, (CURRENT_DATE - 3)::timestamptz + interval '10 hours'),
  ('eeee0000-0000-0000-0000-000000000010','11111111-1111-1111-1111-000000000002','55555555-5555-5555-5555-000000000005', 4, 40, '{2,0,1,2,2}', 8, (CURRENT_DATE - 2)::timestamptz + interval '10 hours'),
  ('eeee0000-0000-0000-0000-000000000011','11111111-1111-1111-1111-000000000003','55555555-5555-5555-5555-000000000001', 3, 30, '{0,2,2,0,2}', 4, (CURRENT_DATE - 6)::timestamptz + interval '11 hours'),
  ('eeee0000-0000-0000-0000-000000000012','11111111-1111-1111-1111-000000000003','55555555-5555-5555-5555-000000000003', 4, 40, '{2,1,2,2,1}', 5, (CURRENT_DATE - 4)::timestamptz + interval '11 hours'),
  ('eeee0000-0000-0000-0000-000000000013','11111111-1111-1111-1111-000000000004','55555555-5555-5555-5555-000000000002', 5, 50, '{2,2,2,3,2}', 3, (CURRENT_DATE - 5)::timestamptz + interval '12 hours'),
  ('eeee0000-0000-0000-0000-000000000014','11111111-1111-1111-1111-000000000004','55555555-5555-5555-5555-000000000006', 4, 44, '{2,2,2,2,1}', 4, (CURRENT_DATE - 1)::timestamptz + interval '12 hours'),
  ('eeee0000-0000-0000-0000-000000000015','11111111-1111-1111-1111-000000000005','55555555-5555-5555-5555-000000000005', 3, 30, '{2,0,2,1,2}', 2, (CURRENT_DATE - 2)::timestamptz + interval '13 hours')
ON CONFLICT (id) DO NOTHING;

-- ── 15. GENERAL QUIZ RESULTS ──────────────────────────────────────────────────
INSERT INTO public.general_quiz_results (id, user_id, difficulty, score, total, xp_earned, answers, completed_at) VALUES
  ('ffff0000-0000-0000-0000-000000000001','11111111-1111-1111-1111-000000000001','easy',   5, 5, 50, '[0,1,1,1,2]'::jsonb, now() - interval '10 days'),
  ('ffff0000-0000-0000-0000-000000000002','11111111-1111-1111-1111-000000000001','medium', 4, 5, 60, '[0,3,1,2,3]'::jsonb, now() - interval '8 days'),
  ('ffff0000-0000-0000-0000-000000000003','11111111-1111-1111-1111-000000000001','hard',   3, 5, 60, '[1,1,2,1,1]'::jsonb, now() - interval '6 days'),
  ('ffff0000-0000-0000-0000-000000000004','11111111-1111-1111-1111-000000000002','easy',   5, 5, 50, '[0,1,1,1,2]'::jsonb, now() - interval '9 days'),
  ('ffff0000-0000-0000-0000-000000000005','11111111-1111-1111-1111-000000000002','medium', 5, 5, 75, '[0,3,1,2,3]'::jsonb, now() - interval '7 days'),
  ('ffff0000-0000-0000-0000-000000000006','11111111-1111-1111-1111-000000000003','easy',   4, 5, 40, '[0,1,0,1,2]'::jsonb, now() - interval '12 days'),
  ('ffff0000-0000-0000-0000-000000000007','11111111-1111-1111-1111-000000000004','medium', 3, 5, 45, '[0,3,2,2,0]'::jsonb, now() - interval '5 days'),
  ('ffff0000-0000-0000-0000-000000000008','11111111-1111-1111-1111-000000000005','easy',   3, 5, 30, '[0,1,0,0,2]'::jsonb, now() - interval '7 days'),
  ('ffff0000-0000-0000-0000-000000000009','11111111-1111-1111-1111-000000000006','easy',   5, 5, 50, '[0,1,1,1,2]'::jsonb, now() - interval '4 days'),
  ('ffff0000-0000-0000-0000-000000000010','11111111-1111-1111-1111-000000000006','hard',   2, 5, 40, '[1,3,2,0,1]'::jsonb, now() - interval '2 days')
ON CONFLICT (id) DO NOTHING;

-- ── 16. CROSSWORD RESULTS ────────────────────────────────────────────────────
INSERT INTO public.crossword_results (id, user_id, puzzle_date, completed, xp_earned, time_seconds, completed_at) VALUES
  ('cccc0000-0000-0000-0000-000000000001','11111111-1111-1111-1111-000000000001', CURRENT_DATE - 5, true,  30, 287, (CURRENT_DATE - 5)::timestamptz + interval '14 hours'),
  ('cccc0000-0000-0000-0000-000000000002','11111111-1111-1111-1111-000000000001', CURRENT_DATE - 4, true,  30, 312, (CURRENT_DATE - 4)::timestamptz + interval '14 hours'),
  ('cccc0000-0000-0000-0000-000000000003','11111111-1111-1111-1111-000000000002', CURRENT_DATE - 5, true,  30, 418, (CURRENT_DATE - 5)::timestamptz + interval '15 hours'),
  ('cccc0000-0000-0000-0000-000000000004','11111111-1111-1111-1111-000000000003', CURRENT_DATE - 3, true,  30, 521, (CURRENT_DATE - 3)::timestamptz + interval '16 hours'),
  ('cccc0000-0000-0000-0000-000000000005','11111111-1111-1111-1111-000000000004', CURRENT_DATE - 2, false, 10, null,(CURRENT_DATE - 2)::timestamptz + interval '16 hours'),
  ('cccc0000-0000-0000-0000-000000000006','11111111-1111-1111-1111-000000000006', CURRENT_DATE - 1, true,  30, 384, (CURRENT_DATE - 1)::timestamptz + interval '17 hours')
ON CONFLICT (id) DO NOTHING;

-- ── 17. API USAGE LOG (historical ingestion records) ─────────────────────────
INSERT INTO public.api_usage_log (source_name, endpoint, calls_made, calls_remaining, logged_date) VALUES
  ('GNews',       'top-headlines', 12, 88,  CURRENT_DATE - 3),
  ('Guardian',    'search',        18, 482, CURRENT_DATE - 3),
  ('GNews',       'top-headlines', 14, 86,  CURRENT_DATE - 2),
  ('Guardian',    'search',        21, 479, CURRENT_DATE - 2),
  ('GNews',       'top-headlines', 11, 89,  CURRENT_DATE - 1),
  ('Guardian',    'search',        17, 483, CURRENT_DATE - 1)
ON CONFLICT (id) DO NOTHING;

COMMIT;
