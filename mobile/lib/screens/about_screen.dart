import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/nexus_logo.dart';
import '../widgets/owl_mascot.dart';

class AboutScreen extends StatelessWidget {
  final bool isDark;
  const AboutScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF0A3D2E)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      NexusLogoDark(size: 88, showText: false),
                      const SizedBox(height: 16),
                      const Text(
                        'NEXUS',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NEWS APP',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.55),
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: NexusColors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: NexusColors.teal.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: NexusColors.teal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Owl mascot ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  OwlMascot(size: 100, mood: OwlMood.happy),
                  const SizedBox(height: 16),
                  Text(
                    '"Stay informed, stay connected."',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── About section ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Card(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('About Nexus', colors),
                    const SizedBox(height: 12),
                    Text(
                      'Nexus is a geo-contextual news platform that brings you global and local stories in one place. '
                      'Follow journalists, react to articles, play daily quizzes, and stay ahead of what matters — '
                      'wherever you are in the world.',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textPrimary,
                        height: 1.65,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Features ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Card(
                colors: colors,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle('Features', colors),
                    const SizedBox(height: 14),
                    _FeatureRow(emoji: '🌍', title: 'World Map', desc: 'Interactive globe with region news', colors: colors),
                    _FeatureRow(emoji: '📰', title: 'Smart Feed', desc: 'Personalized article feed', colors: colors),
                    _FeatureRow(emoji: '✍️', title: 'Journalist Studio', desc: 'Publish & manage your posts', colors: colors),
                    _FeatureRow(emoji: '🧠', title: 'Daily Quiz', desc: 'Test your news knowledge', colors: colors),
                    _FeatureRow(emoji: '🏆', title: 'Leaderboard', desc: 'Compete with readers worldwide', colors: colors),
                    _FeatureRow(emoji: '⭐', title: 'Premium', desc: 'Arabic feed, 2× XP & ad-free reading', colors: colors),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Links ────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Card(
                colors: colors,
                child: Column(
                  children: [
                    _LinkRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      colors: colors,
                      onTap: () => _openUrl('https://nexus.app/privacy'),
                    ),
                    Divider(height: 1, color: colors.border),
                    _LinkRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      colors: colors,
                      onTap: () => _openUrl('https://nexus.app/terms'),
                    ),
                    Divider(height: 1, color: colors.border),
                    _LinkRow(
                      icon: Icons.mail_outline,
                      label: 'Contact Us',
                      colors: colors,
                      onTap: () => _openUrl('mailto:hello@nexus.app'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Footer ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
              child: Center(
                child: Text(
                  '© 2026 Nexus News App\nBuilt with ❤️ for curious minds',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textSecondary,
                    height: 1.7,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final DynamicColors colors;
  final Widget child;
  const _Card({required this.colors, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: child,
      );
}

Widget _SectionTitle(String text, DynamicColors colors) => Text(
      text,
      style: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
    );

class _FeatureRow extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final DynamicColors colors;
  const _FeatureRow({required this.emoji, required this.title, required this.desc, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                  Text(desc, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DynamicColors colors;
  final VoidCallback onTap;
  const _LinkRow({required this.icon, required this.label, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: colors.textPrimary))),
              Icon(Icons.arrow_forward_ios, size: 14, color: colors.textSecondary),
            ],
          ),
        ),
      );
}
