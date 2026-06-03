-- =============================================================
-- NEXUS FINAL SEED — Rich article data across all 6 world regions
-- 36 articles × 6 regions × varied topics
-- UUID range: AAAAAAAA-AAAA-AAAA-AAAA-0000000000xx
-- Safe to re-run (ON CONFLICT DO NOTHING).
-- =============================================================

BEGIN;

INSERT INTO public.articles (
  id, title, description, content, url,
  source_id, source_name, journalist_id,
  country_code, category, language,
  thumbnail_url, published_at, view_count
) VALUES

-- ─────────────────────────────────────────────────────────────────────────────
-- EUROPE  (GB, FR, DE, IT, NL, ES, SE)
-- ─────────────────────────────────────────────────────────────────────────────

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000001',
  'UK Parliament Passes Landmark Net-Zero Acceleration Bill',
  'The House of Commons voted 412–89 to enshrine binding carbon-reduction targets into law, committing Britain to cut emissions 78% by 2035 compared to 1990 levels. The bill also mandates a new independent climate enforcement body.',
  'MPs backed the legislation after months of cross-party negotiations, with the government citing rising energy prices and extreme weather events as catalysts. Critics from industry groups warned of short-term job losses in fossil-fuel sectors, while climate scientists called the targets the most ambitious of any G7 nation. The King is expected to give Royal Assent within the week.',
  'https://www.theguardian.com/uk/climate-bill-2026',
  '22222222-2222-2222-2222-000000000001', 'The Guardian',
  '33333333-3333-3333-3333-000000000007',
  'GB', 'world', 'en',
  'https://picsum.photos/seed/uk-climate/800/450',
  now() - interval '2 hours', 4210
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000002',
  'Paris Summit: EU Leaders Agree on Unified Migration Framework',
  'European Union heads of state reached a historic compromise in Paris on a continent-wide asylum policy, ending years of political deadlock. The framework introduces shared processing centres and a mandatory solidarity mechanism among member states.',
  'The deal, brokered after 16 hours of talks, distributes responsibility for migrants proportionally by GDP and population. Hungary and Poland initially objected but ultimately signed after securing opt-out clauses for border management. Commissioner for Home Affairs called it "a turning point in European solidarity." Implementation begins in January.',
  'https://www.reuters.com/europe/eu-migration-paris-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000001',
  'FR', 'world', 'en',
  'https://picsum.photos/seed/eu-paris/800/450',
  now() - interval '5 hours', 6830
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000003',
  'Deutsche Bank Invests €2 Billion in European AI Infrastructure',
  'Germany''s largest bank announced a sweeping investment plan to build AI-powered financial services across the eurozone, partnering with three leading tech universities to establish dedicated AI research labs in Frankfurt, Munich, and Berlin.',
  'The initiative, dubbed "Project Minerva," aims to deploy generative AI for credit risk assessment, fraud detection, and personalised wealth management within 18 months. Deutsche Bank CEO stated the move is essential to compete with American and Chinese fintech rivals. The European Central Bank has welcomed the investment but signalled it will issue compliance guidelines on AI decision-making in banking by Q4.',
  'https://www.reuters.com/technology/deutsche-bank-ai-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000010',
  'DE', 'technology', 'en',
  'https://picsum.photos/seed/de-bank-ai/800/450',
  now() - interval '9 hours', 3540
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000004',
  'Roma Wins Champions League Final in Dramatic Penalty Shootout',
  'AS Roma defeated Bayern Munich 4–3 on penalties at Wembley to claim their first UEFA Champions League title, ending a 74-year wait. The match finished 1–1 after extra time in front of 87,000 fans.',
  'Captain Lorenzo Pellegrini converted the decisive kick to send thousands of Roma supporters into ecstasy. Manager José Mourinho, returning to the club for a second stint, wept on the touchline. The victory marks a new era for Italian football, which has produced three European finalists in the past five years. The trophy parade through central Rome attracted an estimated two million people.',
  'https://www.bbc.com/sport/football/champions-league-final-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000006',
  'IT', 'sports', 'en',
  'https://picsum.photos/seed/roma-cl/800/450',
  now() - interval '18 hours', 12900
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000005',
  'Dutch Scientists Develop Blood Test That Detects 50 Cancers Before Symptoms',
  'Researchers at the Amsterdam UMC have published results showing their liquid biopsy test can identify 50 different cancer types from a single blood draw with 94% accuracy, even before patients develop any symptoms. The study, published in Nature Medicine, covers 120,000 participants across five years.',
  'The test analyses cell-free DNA fragments shed by tumours into the bloodstream. Early detection trials showed stage-one cancers identified by the test had a 91% five-year survival rate compared to 58% for cases found through traditional symptom presentation. The Dutch government has pledged €300 million to roll the test out as part of routine health screening by 2028, making the Netherlands the first country to adopt it nationally.',
  'https://www.theguardian.com/science/dutch-cancer-test-2026',
  '22222222-2222-2222-2222-000000000001', 'The Guardian',
  '33333333-3333-3333-3333-000000000005',
  'NL', 'health', 'en',
  'https://picsum.photos/seed/nl-cancer/800/450',
  now() - interval '1 day', 8740
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000006',
  'Pedro Almodóvar''s Final Film Wins Palme d''Or at Cannes',
  'Spanish director Pedro Almodóvar received the Palme d''Or for "La Última Luz," a sweeping meditation on grief and memory set across three decades of Madrid life. The jury called it "a masterwork that redefines the possibilities of cinema."',
  'The 76-year-old auteur, attending Cannes for the 18th time, broke down in tears accepting the award. "La Última Luz" stars Penélope Cruz and features an original score by Jonny Greenwood. Distributed by Sony Pictures Classics internationally, the film will open in 45 countries from September. Almodóvar has confirmed this will be his final feature-length directorial project.',
  'https://www.bbc.com/culture/cannes-almodovar-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000011',
  'ES', 'entertainment', 'en',
  'https://picsum.photos/seed/cannes-es/800/450',
  now() - interval '30 hours', 5620
),

-- ─────────────────────────────────────────────────────────────────────────────
-- ASIA  (JP, KR, IN, CN, SG, TH)
-- ─────────────────────────────────────────────────────────────────────────────

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000007',
  'Japan Launches World''s First Commercial Quantum Internet Node',
  'NTT and Toshiba jointly activated a quantum key distribution network linking Tokyo, Osaka, and Nagoya, marking the world''s first commercially operated quantum-encrypted internet backbone. The network offers theoretically unhackable communications for financial and government clients.',
  'The 750-kilometre fibre-optic network uses photon entanglement to distribute cryptographic keys that are physically impossible to intercept without detection. Initial customers include the Bank of Japan, the Ministry of Finance, and three major trading houses. Japan''s government allocated ¥400 billion ($2.6 billion) to the project as part of its Quantum Leap initiative. NTT plans to extend the network internationally to South Korea and Australia by 2028.',
  'https://apnews.com/technology/japan-quantum-internet-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000009',
  'JP', 'technology', 'en',
  'https://picsum.photos/seed/jp-quantum/800/450',
  now() - interval '4 hours', 7320
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000008',
  'Korean Drama "Midnight Horizon" Breaks Netflix Global Viewership Record',
  '"Midnight Horizon," a political thriller set in a divided Korea, has accumulated 450 million viewing hours in its first four weeks on Netflix — surpassing the previous record held by "Squid Game." The show has topped the charts in 93 countries.',
  'Creator Park Ji-won drew on her experience as a former intelligence analyst to craft a plot centred on a female spy navigating reunification negotiations. Netflix invested $180 million in the production, the largest ever for a Korean series. South Korea''s Cultural Ministry credited the show with driving a 34% spike in Korean language course enrolments globally. Season two has already been commissioned with a reported $220 million budget.',
  'https://apnews.com/entertainment/midnight-horizon-netflix-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000011',
  'KR', 'entertainment', 'en',
  'https://picsum.photos/seed/kr-drama/800/450',
  now() - interval '7 hours', 15800
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000009',
  'India''s Startup Ecosystem Raises Record $48 Billion in First Half of 2026',
  'Indian startups attracted $48.3 billion in venture and private equity funding in the first six months of 2026, surpassing the full-year record set in 2021 and cementing the country as the world''s third-largest startup economy by capital raised.',
  'Fintech, health-tech, and green energy dominated deal flow, with eight new unicorns minted during the period. Bengaluru remained the top hub, accounting for 41% of deals, while Hyderabad and Pune gained ground. PM Modi unveiled a new regulatory sandbox allowing startups to pilot products in restricted geographies before national rollout. Analysts point to a maturing talent pool of 4.5 million STEM graduates annually as a key competitive advantage.',
  'https://www.reuters.com/business/india-startup-record-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000004',
  'IN', 'business', 'en',
  'https://picsum.photos/seed/in-startup/800/450',
  now() - interval '12 hours', 6150
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000010',
  'China Pledges Carbon Neutrality by 2055, Five Years Early',
  'President Xi Jinping announced that China will achieve carbon neutrality by 2055, accelerating its previous 2060 target, citing faster-than-expected progress in renewable energy deployment. China now generates 45% of its electricity from solar and wind.',
  'The announcement, made at the Beijing Climate Summit, was accompanied by a commitment to retire all coal-fired power plants by 2040 and invest $1.2 trillion in green infrastructure over the next decade. The EU and United States hailed the pledge as a "game-changer" for global climate goals. China also revealed plans for the world''s largest battery storage facility in Inner Mongolia, capable of powering 50 million homes for 12 hours.',
  'https://www.theguardian.com/world/china-climate-2026',
  '22222222-2222-2222-2222-000000000001', 'The Guardian',
  '33333333-3333-3333-3333-000000000007',
  'CN', 'world', 'en',
  'https://picsum.photos/seed/cn-climate/800/450',
  now() - interval '20 hours', 11200
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000011',
  'Singapore Becomes First City to Deploy Fully Autonomous Bus Fleet',
  'Singapore''s Land Transport Authority activated a fully driverless public bus network across all 12 major routes, making Singapore the world''s first city to operate autonomous buses at full commercial scale without safety drivers on board.',
  'The 350-vehicle fleet, built by a consortium of Volvo Autonomous Solutions and ST Engineering, uses lidar, radar, and AI vision systems to navigate the island''s complex traffic. Fares are unchanged. The LTA reported zero safety incidents during a 24-month pilot phase covering 2.1 million kilometres. The project is expected to save S$180 million annually in labour costs, which will be reinvested in expanding routes to underserved neighbourhoods.',
  'https://apnews.com/technology/singapore-autonomous-bus-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000009',
  'SG', 'technology', 'en',
  'https://picsum.photos/seed/sg-bus/800/450',
  now() - interval '36 hours', 4890
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000012',
  'Thailand Wins Gold Rush at Southeast Asian Games, Tops Medal Table',
  'Thailand claimed 142 gold medals to top the Southeast Asian Games medal table for the first time since 2007, excelling in aquatics, athletics, and the newly added e-sports category. The Games, hosted in Chiang Mai, drew 5,000 athletes from 11 nations.',
  'Thai swimmer Napatsorn Suangam shattered the SEA record in the 200m butterfly, while the national Muay Thai team swept all weight categories. The e-sports events — featuring titles including Mobile Legends and Dota 2 — drew the largest crowds of any single venue with 18,000 tickets selling out within hours. Sports Minister Alphie Thasana called it "Thailand''s greatest multi-sport achievement."',
  'https://apnews.com/sports/sea-games-thailand-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000006',
  'TH', 'sports', 'en',
  'https://picsum.photos/seed/th-seagames/800/450',
  now() - interval '48 hours', 3760
),

-- ─────────────────────────────────────────────────────────────────────────────
-- MIDDLE EAST  (LB, SA, AE, TR, IL, JO)
-- ─────────────────────────────────────────────────────────────────────────────

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000013',
  'Lebanon Signs $4 Billion Reconstruction Partnership with World Bank',
  'The Lebanese government and the World Bank signed a landmark $4 billion reconstruction agreement in Beirut, the largest international commitment to Lebanon''s recovery since the 2020 port explosion. Funds will target infrastructure, electricity, and social housing.',
  'Prime Minister Nawaf Salam, elected following last year''s parliamentary elections, described the deal as "a new chapter for Lebanon." The agreement includes strict anti-corruption conditionality, with an independent oversight board required before each tranche is released. The IMF separately confirmed it will resume a $3 billion credit line suspended in 2022 once Lebanon passes banking reform legislation expected before year''s end.',
  'https://www.aljazeera.com/economy/lebanon-world-bank-2026',
  '22222222-2222-2222-2222-000000000004', 'Al Jazeera',
  '33333333-3333-3333-3333-000000000012',
  'LB', 'world', 'en',
  'https://picsum.photos/seed/lb-reconstruct/800/450',
  now() - interval '3 hours', 9410
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000014',
  'Saudi Arabia Unveils NEOM Phase Two: A Floating Archipelago City',
  'Saudi Crown Prince Mohammed bin Salman launched Phase Two of the NEOM megaproject, introducing "Sindalah+" — a network of 17 artificial islands in the Red Sea designed to host 200,000 residents and 4 million annual visitors by 2040.',
  'The development includes a zero-emission ferry network, a vertical farming district producing 40% of residents'' food, and a cultural quarter featuring institutions partnered with the Louvre and MIT. Critics from human rights organisations renewed concerns about displacement of the Huwaitat tribe, which the government denies. The project will create an estimated 380,000 jobs. Saudi Aramco has committed to carbon-offsetting the entire construction phase.',
  'https://www.reuters.com/business/saudi-neom-phase2-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000004',
  'SA', 'business', 'en',
  'https://picsum.photos/seed/sa-neom/800/450',
  now() - interval '8 hours', 7650
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000015',
  'Dubai Opens World''s Largest Climate-Controlled Vertical Farm',
  'Dubai Municipality inaugurated the world''s largest vertical farm — a 75,000 square-metre facility in Al Quoz producing 2,000 tonnes of leafy vegetables annually without soil or sunlight, using 95% less water than conventional agriculture.',
  'The facility, built by AeroFarms in partnership with the UAE government, uses AI-controlled LED lighting tuned to each plant species'' optimal growth spectrum. It produces 130 varieties of lettuce, herbs, and microgreens destined for UAE supermarkets and airline catering. With the UAE importing 90% of its food, officials said vertical farming is central to national food security strategy. A second, larger facility is planned for Abu Dhabi.',
  'https://www.bbc.com/news/dubai-vertical-farm-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000007',
  'AE', 'technology', 'en',
  'https://picsum.photos/seed/ae-farm/800/450',
  now() - interval '14 hours', 5380
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000016',
  'Turkey Hosts Historic UEFA Euro 2028 Draw in Istanbul',
  'Istanbul''s Halic Congress Centre hosted the UEFA Euro 2028 final tournament draw, with Turkey''s national team placed in a group alongside Spain, Denmark, and Albania. The tournament will be jointly hosted by Turkey and Italy across 10 stadiums.',
  'President Erdoğan attended the ceremony alongside UEFA president Aleksander Čeferin, who praised the two countries'' modernised infrastructure. Turkey''s İstanbul Stadium — newly expanded to 85,000 seats — will host the final on July 14. Ticket demand has exceeded 48 million applications for 2.5 million available seats. The tournament is expected to generate €6.8 billion for the two host economies.',
  'https://www.bbc.com/sport/football/euro-2028-draw-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000006',
  'TR', 'sports', 'en',
  'https://picsum.photos/seed/tr-euro/800/450',
  now() - interval '22 hours', 8900
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000017',
  'Israeli Researchers Develop Desalination Membrane That Cuts Energy by 70%',
  'Scientists at the Technion–Israel Institute of Technology have created a graphene-oxide desalination membrane that requires 70% less energy than conventional reverse-osmosis technology, a breakthrough that could transform freshwater production in arid regions worldwide.',
  'The membrane filters salt ions through atomic-scale pores while allowing water molecules to pass at record flow rates. Lab tests showed it can process seawater to drinking-water standard at a cost of $0.18 per cubic metre, compared to $0.65 for current best-in-class RO systems. Israel''s National Water Authority has approved a pilot plant in Hadera to validate commercial-scale performance. If successful, the technology will be licensed globally through a new company, AquaGraph.',
  'https://www.reuters.com/science/israel-desalination-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000005',
  'IL', 'science', 'en',
  'https://picsum.photos/seed/il-desal/800/450',
  now() - interval '40 hours', 6720
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000018',
  'Jordan Launches Free Universal Mental Health App Backed by WHO',
  'The Jordanian Ministry of Health, in partnership with the World Health Organization, launched "Raha" — a free mental health application available in Arabic and English offering therapy, mindfulness, and crisis support to all residents of Jordan and the broader Arab world.',
  'The app uses a hybrid model combining AI-guided cognitive behavioural therapy modules with access to licensed psychologists for escalated cases. During a 10-month beta phase with 120,000 users, clinical anxiety scores improved by an average of 38%. The WHO will use Jordan as a model for rolling out similar platforms across 15 other lower-middle-income countries. The app is available on iOS and Android with no subscription fees.',
  'https://www.aljazeera.com/health/jordan-mental-health-app-2026',
  '22222222-2222-2222-2222-000000000004', 'Al Jazeera',
  '33333333-3333-3333-3333-000000000005',
  'JO', 'health', 'en',
  'https://picsum.photos/seed/jo-health/800/450',
  now() - interval '52 hours', 4230
),

-- ─────────────────────────────────────────────────────────────────────────────
-- AMERICAS  (US, CA, BR, MX, CO, AR)
-- ─────────────────────────────────────────────────────────────────────────────

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000019',
  'OpenAI Releases GPT-6 With Real-Time Scientific Reasoning Capabilities',
  'OpenAI unveiled GPT-6, its most advanced language model, featuring a dedicated scientific reasoning module capable of independently generating and evaluating research hypotheses across biology, chemistry, and physics — a step toward autonomous scientific discovery.',
  'In benchmark tests, GPT-6 correctly solved 91% of graduate-level chemistry problems and proposed three novel protein-folding configurations that were subsequently validated in wet-lab experiments by partner institutions. CEO Sam Altman announced a $5 monthly price reduction for ChatGPT Plus subscriptions to broaden access. The EU''s AI Office immediately opened a review to assess GPT-6 under the AI Act''s high-risk provisions, while the US National Institutes of Health signed a research partnership agreement.',
  'https://apnews.com/technology/openai-gpt6-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000002',
  'US', 'technology', 'en',
  'https://picsum.photos/seed/us-gpt6/800/450',
  now() - interval '1 hour', 22400
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000020',
  'Canada Announces Largest Immigration Reform in 50 Years',
  'Prime Minister Mark Carney unveiled a sweeping overhaul of Canada''s immigration system, introducing a merit-and-needs matrix that prioritises healthcare workers, engineers, and climate scientists, while cutting processing times from 24 months to a target of 90 days.',
  'The reform also creates a new "Climate Resilience Visa" for individuals from countries facing severe climate displacement, allowing up to 50,000 additional admissions annually. A new digital identity system using blockchain credentials will verify professional qualifications without physical document review. Opposition parties broadly welcomed the healthcare worker pathway but challenged the 90-day processing pledge as unrealistic given current staffing levels at IRCC.',
  'https://apnews.com/world-news/canada-immigration-reform-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000001',
  'CA', 'world', 'en',
  'https://picsum.photos/seed/ca-immigration/800/450',
  now() - interval '6 hours', 8110
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000021',
  'Brazil''s Neymar Scores Hat-Trick on International Return at 34',
  'Neymar Jr silenced doubters with a stunning hat-trick in Brazil''s 4–1 victory over Argentina in the Copa América group stage, his first international appearance since a serious knee injury ruled him out for 14 months.',
  'Playing from the left wing in front of 80,000 fans in São Paulo''s Estádio do Morumbi, Neymar delivered two free-kick goals and a solo run from the halfway line that drew comparisons to Messi''s 2006 World Cup qualifier goal. Head coach Fernando Diniz confirmed Neymar will start in the quarter-final if fitness allows. The performance trending globally as "#NeymarIsBack" accumulated 2.4 billion impressions within 24 hours.',
  'https://www.bbc.com/sport/football/neymar-copa-america-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000006',
  'BR', 'sports', 'en',
  'https://picsum.photos/seed/br-neymar/800/450',
  now() - interval '10 hours', 18700
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000022',
  'Mexico''s Manufacturing Sector Surpasses China as Top US Import Source',
  'For the second consecutive year, Mexico has overtaken China as the largest source of goods imported by the United States, with bilateral trade reaching $940 billion — a 14% year-on-year increase driven by nearshoring of semiconductor, EV battery, and aerospace manufacturing.',
  'The shift reflects a sustained decoupling of US-China supply chains accelerated by tariff policies and geopolitical uncertainty. Monterrey and Guadalajara have attracted $62 billion in new factory investments since 2024. Mexico''s Economy Minister Raquel Buenrostro said the country is on track to become a top-five global manufacturing economy by 2030. The peso reached a 12-year high against the dollar in response to the trade data.',
  'https://www.reuters.com/business/mexico-manufacturing-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000004',
  'MX', 'business', 'en',
  'https://picsum.photos/seed/mx-mfg/800/450',
  now() - interval '16 hours', 5940
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000023',
  'Colombia Deploys AI-Powered Diagnostic Clinics to 500 Rural Villages',
  'The Colombian Ministry of Health activated a network of 500 autonomous diagnostic kiosks across remote Andean and Amazonian communities, capable of conducting blood panels, ECGs, eye scans, and chest X-rays with results interpreted by AI within 90 seconds.',
  'The kiosks, housed in solar-powered shipping containers, are staffed by community health workers who can escalate results to telemedicine doctors in Bogotá. In a six-month pilot across 120 villages, the system identified 2,300 previously undiagnosed cases of diabetes, hypertension, and tuberculosis. The Pan American Health Organization has called the programme a model for universal health coverage in geographically challenging environments.',
  'https://apnews.com/health/colombia-ai-clinics-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000005',
  'CO', 'health', 'en',
  'https://picsum.photos/seed/co-health/800/450',
  now() - interval '28 hours', 4610
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000024',
  'Argentina''s Economy Grows 6.2% as Milei Reforms Take Hold',
  'Argentina posted GDP growth of 6.2% in the first quarter of 2026, its fastest expansion in a decade, as President Javier Milei''s austerity programme turned a $30 billion fiscal deficit into a $2 billion surplus within 18 months of taking office.',
  'Inflation, once running at 210% annually, has fallen to 38% and is projected to reach single digits by December. The IMF approved a new $20 billion credit line and praised the reform programme as "extraordinary." However, poverty remains at 42% — a key vulnerability Milei''s opponents highlight ahead of midterm elections in October. The peso has stabilised at a managed float and dollar reserves are at their highest since 2018.',
  'https://www.reuters.com/world/americas/argentina-economy-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000004',
  'AR', 'world', 'en',
  'https://picsum.photos/seed/ar-economy/800/450',
  now() - interval '44 hours', 7380
),

-- ─────────────────────────────────────────────────────────────────────────────
-- AFRICA  (ZA, NG, KE, MA, ET, GH)
-- ─────────────────────────────────────────────────────────────────────────────

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000025',
  'South Africa Chairs G20 Summit with African Development at Centre Stage',
  'South Africa opened its G20 presidency with a summit in Johannesburg focused on reforming multilateral development banks to unlock $500 billion annually for African infrastructure, healthcare, and climate adaptation.',
  'President Cyril Ramaphosa chaired the opening session alongside leaders from 19 nations plus the African Union, which joined the G20 as a permanent member in 2023. South Africa secured commitments from the US, EU, and China to co-finance a 10,000 kilometre trans-African rail corridor and a continental electricity grid powered by the Saharan solar belt. The Johannesburg Declaration included a first-ever binding pledge on debt restructuring for low-income nations.',
  'https://www.aljazeera.com/economy/south-africa-g20-2026',
  '22222222-2222-2222-2222-000000000004', 'Al Jazeera',
  '33333333-3333-3333-3333-000000000008',
  'ZA', 'world', 'en',
  'https://picsum.photos/seed/za-g20/800/450',
  now() - interval '5 hours', 10200
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000026',
  'Lagos Becomes Africa''s First City to Host a Major AI Research Hub',
  'Google DeepMind and Microsoft jointly opened Africa''s largest artificial intelligence research centre in Lagos, a 12,000 square-metre facility that will employ 800 researchers and focus on AI applications for agriculture, healthcare, and climate modelling across Sub-Saharan Africa.',
  'The hub, built in partnership with the Federal Government of Nigeria and Lagos State, offers a two-year fellowship programme for African AI researchers with fully funded PhD pathways. Nigeria''s President Tinubu described it as "the most significant technology investment in Africa''s history." DeepMind CEO Demis Hassabis noted that African training data has historically been underrepresented in global AI models, which the centre aims to address.',
  'https://www.bbc.com/technology/nigeria-ai-hub-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000002',
  'NG', 'technology', 'en',
  'https://picsum.photos/seed/ng-ai/800/450',
  now() - interval '11 hours', 8470
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000027',
  'Kenya''s M-Pesa Reaches One Billion Transactions Per Month Milestone',
  'Safaricom announced that M-Pesa, its mobile money platform, processed one billion transactions in a single month for the first time, handling $42 billion in transaction value — larger than Kenya''s formal banking sector combined.',
  'Launched in 2007 as a simple SMS-based payment system, M-Pesa now offers savings accounts, microloans, insurance, and cross-border transfers across seven African countries. CEO Peter Ndegwa announced an expansion into Ethiopia, Africa''s second most populous country, in partnership with the state-owned Ethio Telecom. The World Bank credits M-Pesa with lifting 2% of Kenyan households out of extreme poverty by providing financial access to previously unbanked populations.',
  'https://www.reuters.com/technology/mpesa-billion-2026',
  '22222222-2222-2222-2222-000000000003', 'Reuters',
  '33333333-3333-3333-3333-000000000004',
  'KE', 'business', 'en',
  'https://picsum.photos/seed/ke-mpesa/800/450',
  now() - interval '19 hours', 6810
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000028',
  'Morocco''s Noor Solar Complex Achieves 100% Renewable Electricity for 24 Hours',
  'Morocco''s Noor solar complex in Ouarzazate generated enough electricity from solar power alone to supply the entire national grid for a continuous 24-hour period — a world first for a country of Morocco''s size — marking a major milestone in Africa''s energy transition.',
  'The achievement was enabled by newly installed molten-salt thermal storage units that allow the Noor III concentrated solar plant to generate power throughout the night. Morocco exports surplus electricity to Spain and Portugal via undersea cable. King Mohammed VI pledged that Morocco will be carbon-neutral by 2045, 15 years ahead of its prior commitment. The International Energy Agency praised the country as "proof that clean energy transitions in the Global South are not only possible but economically compelling."',
  'https://www.theguardian.com/environment/morocco-solar-2026',
  '22222222-2222-2222-2222-000000000001', 'The Guardian',
  '33333333-3333-3333-3333-000000000007',
  'MA', 'science', 'en',
  'https://picsum.photos/seed/ma-solar/800/450',
  now() - interval '33 hours', 7950
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000029',
  'Ethiopia Eliminates Malaria in 60% of Formerly Endemic Districts',
  'Ethiopia''s Ministry of Health reported that 60% of districts previously classified as malaria-endemic have recorded zero cases for 24 consecutive months, the result of a decade-long campaign combining insecticide-treated nets, indoor spraying, and a new locally-manufactured rapid diagnostic test.',
  'The malaria mortality rate has fallen 89% nationally since 2015. The success has been attributed partly to the "Shimeles Drip" — a community-based surveillance system named after its inventor, nurse Shimeles Alemu, which uses SMS reports from village health workers to trigger rapid response teams within 48 hours of a positive case. The WHO has nominated the programme for the Global Health Prize.',
  'https://www.aljazeera.com/health/ethiopia-malaria-2026',
  '22222222-2222-2222-2222-000000000004', 'Al Jazeera',
  '33333333-3333-3333-3333-000000000005',
  'ET', 'health', 'en',
  'https://picsum.photos/seed/et-malaria/800/450',
  now() - interval '50 hours', 5130
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000030',
  'Ghana''s Black Stars Qualify for 2026 World Cup in Final-Minute Thriller',
  'Ghana secured their spot in the 2026 FIFA World Cup with a 2–1 victory over Tunisia in Accra, with captain Thomas Partey converting a 94th-minute penalty to seal qualification. The Black Stars will appear in their fifth World Cup, to be jointly hosted by the US, Canada, and Mexico.',
  'The stadium erupted as Partey stepped up under enormous pressure, having missed a penalty in the reverse fixture. Coach Otto Addo called it "the greatest moment of my coaching career." Ghana is placed in Pot 3 for the draw and could face past nemeses Portugal or Uruguay in the group stage. The GFA announced a record-breaking $8 million bonus pool for the squad should they progress past the round of 16.',
  'https://www.bbc.com/sport/football/ghana-world-cup-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000006',
  'GH', 'sports', 'en',
  'https://picsum.photos/seed/gh-football/800/450',
  now() - interval '6 hours', 13500
),

-- ─────────────────────────────────────────────────────────────────────────────
-- OCEANIA  (AU, NZ, FJ)
-- ─────────────────────────────────────────────────────────────────────────────

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000031',
  'Australia Unveils Brisbane 2032 Olympics Master Plan: Fully Carbon-Neutral Games',
  'The Australian Olympic Committee and Queensland government unveiled the final master plan for the Brisbane 2032 Olympics, confirming all venues will run on 100% renewable energy, athletes will travel using hydrogen-powered transport, and the Games will be the first in Olympic history to achieve net-zero carbon emissions.',
  'The plan covers 37 venues across South-East Queensland, with 85% of existing facilities repurposed rather than newly built. A $2.7 billion athletes'' village in Northshore Hamilton will convert to affordable housing post-Games. IOC President Sebastian Coe called Brisbane 2032 "the blueprint for sustainable mega-events." Ticket sales open in 2030 with a new dynamic pricing model capping lower-tier seats at AUD $45.',
  'https://apnews.com/sports/brisbane-2032-olympics-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000006',
  'AU', 'sports', 'en',
  'https://picsum.photos/seed/au-olympics/800/450',
  now() - interval '7 hours', 9320
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000032',
  'New Zealand Rolls Out Universal Mental Health Coverage for Under-25s',
  'New Zealand became the first country in the world to offer fully government-funded mental health treatment — including therapy, psychiatry, and digital tools — to all citizens and permanent residents under the age of 25, under legislation passed unanimously by Parliament.',
  'The programme, estimated to cost NZD $1.4 billion annually, eliminates out-of-pocket costs for any mental health service for young New Zealanders. Early-access data from the six-month pilot showed a 31% reduction in emergency psychiatric presentations among under-18s. Prime Minister Christopher Luxon called youth mental health "the defining health challenge of our generation." Australia, Canada, and Scotland have expressed interest in adopting similar frameworks.',
  'https://www.theguardian.com/world/new-zealand-mental-health-2026',
  '22222222-2222-2222-2222-000000000001', 'The Guardian',
  '33333333-3333-3333-3333-000000000005',
  'NZ', 'health', 'en',
  'https://picsum.photos/seed/nz-mentalhealth/800/450',
  now() - interval '15 hours', 7440
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000033',
  'Australian Scientists Harness Wave Energy to Power Remote Island Communities',
  'Researchers at the University of Western Australia, in partnership with Carnegie Clean Energy, have deployed a new oscillating wave surge converter off the coast of Rottnest Island that generates enough electricity to power 4,000 homes from ocean waves alone, at a cost competitive with offshore wind.',
  'The device, called CETO 6, sits fully submerged to avoid visual impact and storm damage. Its modular design allows multiple units to be linked in arrays. The technology is being fast-tracked for deployment in the Pacific Islands, where diesel generation currently costs up to seven times the Australian mainland average. ARENA, Australia''s renewable energy agency, has approved $180 million for a Pacific rollout programme beginning in Tonga and Vanuatu.',
  'https://www.bbc.com/science/australia-wave-energy-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000007',
  'AU', 'science', 'en',
  'https://picsum.photos/seed/au-wave/800/450',
  now() - interval '26 hours', 4870
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000034',
  'New Zealand Hosts Pacific Islands Forum Amid Rising Sea-Level Crisis',
  'Auckland hosted the annual Pacific Islands Forum with climate change dominating the agenda, as leaders from 18 Pacific nations presented evidence that six low-lying atoll islands have become permanently uninhabitable since 2020 due to sea-level rise and king tide flooding.',
  'Tuvalu and Kiribati formally requested the Forum endorse a new legal framework giving climate-displaced Pacific peoples permanent residency rights in Australia and New Zealand. Both governments signalled conditional support. The Forum communiqué called for a global fossil fuel non-proliferation treaty and pledged $800 million in collective climate resilience funding. Australia committed to accept 3,000 Pacific climate refugees annually as a starting figure.',
  'https://apnews.com/world-news/pacific-forum-climate-2026',
  '22222222-2222-2222-2222-000000000006', 'Associated Press',
  '33333333-3333-3333-3333-000000000001',
  'NZ', 'world', 'en',
  'https://picsum.photos/seed/nz-pacific/800/450',
  now() - interval '38 hours', 6230
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000035',
  'Fiji Leads Pacific-Wide Coral Reef Restoration Programme',
  'The Fijian government launched the Pacific Coral Alliance — a coalition of 14 island nations using 3D-printed coral substrate and heat-resistant coral cultivars developed at the Australian Institute of Marine Science — to restore 5,000 hectares of degraded reef by 2030.',
  'The programme, funded by a $340 million grant from the Global Environment Facility, trains local fishermen as "reef rangers" who maintain restoration plots and monitor biodiversity recovery. Early sites planted in 2024 show 40% coral coverage, compared to 8% in unrestored control areas. Fiji''s coral reefs support 70% of national fishery stocks and generate FJD $900 million in annual tourism revenue — economic value the government says makes restoration a national security issue.',
  'https://www.theguardian.com/environment/fiji-coral-2026',
  '22222222-2222-2222-2222-000000000001', 'The Guardian',
  '33333333-3333-3333-3333-000000000007',
  'FJ', 'science', 'en',
  'https://picsum.photos/seed/fj-coral/800/450',
  now() - interval '55 hours', 3980
),

(
  'aaaaaaaa-aaaa-aaaa-aaaa-000000000036',
  'Australia Tops World University Rankings for STEM Research Output',
  'Three Australian universities — ANU, Melbourne, and Sydney — featured in the top 10 of the 2026 QS World University Rankings for STEM research output, the first time a non-US or UK country has achieved this, reflecting a decade of targeted government investment in research infrastructure.',
  'Australia''s research spending as a percentage of GDP rose from 1.8% to 2.7% since 2016. The government''s "Quantum Century" initiative and a $6 billion National Science and Industry Endowment Fund are credited with the breakthrough. International student enrolments in Australian STEM programmes rose 22% in 2025, generating AUD $12 billion for the higher education sector. Critics note teaching quality metrics and domestic student outcomes have not improved at the same pace.',
  'https://www.bbc.com/education/australia-stem-rankings-2026',
  '22222222-2222-2222-2222-000000000002', 'BBC News',
  '33333333-3333-3333-3333-000000000002',
  'AU', 'science', 'en',
  'https://picsum.photos/seed/au-stem/800/450',
  now() - interval '62 hours', 5290
)

ON CONFLICT (id) DO NOTHING;

COMMIT;
