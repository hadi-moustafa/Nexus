import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                      onTap: () => _showPrivacyPolicy(context, colors),
                    ),
                    Divider(height: 1, color: colors.border),
                    _LinkRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      colors: colors,
                      onTap: () => _showTermsOfService(context, colors),
                    ),
                    Divider(height: 1, color: colors.border),
                    _LinkRow(
                      icon: Icons.mail_outline,
                      label: 'Contact Us',
                      colors: colors,
                      onTap: () => _showContactUs(context, colors),
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

  void _showPrivacyPolicy(BuildContext context, DynamicColors colors) {
    _showTextDialog(
      context: context,
      colors: colors,
      title: 'Privacy Policy',
      content: '''Nexus respects your privacy. Here is how we handle your information.

INFORMATION WE COLLECT
• Account details you provide: email address and display name.
• Usage data: articles read, quiz scores, reactions, bookmarks, and streak activity used to personalise your experience.
• Device information (OS version, app version) for troubleshooting purposes only.

HOW WE USE IT
Your data powers your personalised news feed, tracks your quiz streak and leaderboard rank, and lets you save articles. We do not sell or rent your personal data to third parties.

DATA STORAGE & SECURITY
All data is stored on Supabase-managed servers with encryption in transit (TLS) and at rest. Access is restricted to authorised services only.

YOUR RIGHTS
You may update your display name at any time in Settings. To permanently delete your account and all associated data, contact us at balhashawraa4@gmail.com.

CHANGES TO THIS POLICY
We may update this policy as the app evolves. Continued use of Nexus after changes constitutes acceptance of the updated policy.

Last updated: July 2026''',
    );
  }

  void _showTermsOfService(BuildContext context, DynamicColors colors) {
    _showTextDialog(
      context: context,
      colors: colors,
      title: 'Terms of Service',
      content: '''By using Nexus you agree to the following terms.

1. ACCOUNT RESPONSIBILITY
You are responsible for keeping your login credentials confidential. You must not share your account or impersonate other users.

2. ACCEPTABLE USE
You agree not to post content that is illegal, hateful, defamatory, or misleading. Violations may result in account suspension or permanent removal.

3. JOURNALIST CONTENT
Journalists approved by Nexus may publish posts. All published content must be original and factual. Nexus reserves the right to remove content that violates our standards without notice.

4. PREMIUM SUBSCRIPTION
Premium features are available via monthly or annual subscription. Subscriptions renew automatically unless cancelled before the renewal date. No refunds are issued for partial billing periods.

5. INTELLECTUAL PROPERTY
The Nexus name, logo, and original content are protected by copyright. You may not reproduce or redistribute them without written permission.

6. LIMITATION OF LIABILITY
Nexus is provided "as is." We make no warranties regarding uptime, accuracy, or content availability. We are not liable for any direct or indirect loss arising from use of the app.

7. GOVERNING LAW
These terms are governed by the laws of Lebanon.

8. UPDATES
We may revise these terms at any time. Your continued use of Nexus constitutes acceptance of the latest version.

Last updated: July 2026''',
    );
  }

  void _showContactUs(BuildContext context, DynamicColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NexusColors.teal.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mail_outline, color: NexusColors.teal, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Contact Us',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ContactRow(
                icon: Icons.person_outline,
                label: 'Name',
                value: 'Hawraa Balhas',
                colors: colors,
                onCopy: () {
                  Clipboard.setData(const ClipboardData(text: 'Hawraa Balhas'));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Name copied'), duration: Duration(seconds: 1)),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ContactRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: '76 809 947',
                colors: colors,
                onCopy: () {
                  Clipboard.setData(const ClipboardData(text: '76809947'));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Phone number copied'), duration: Duration(seconds: 1)),
                  );
                },
              ),
              const SizedBox(height: 14),
              _ContactRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: 'balhashawraa4@gmail.com',
                colors: colors,
                onCopy: () {
                  Clipboard.setData(const ClipboardData(text: 'balhashawraa4@gmail.com'));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Email address copied'), duration: Duration(seconds: 1)),
                  );
                },
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close', style: TextStyle(color: NexusColors.teal)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextDialog({
    required BuildContext context,
    required DynamicColors colors,
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colors.border),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textPrimary,
                    height: 1.7,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close', style: TextStyle(color: NexusColors.teal)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final DynamicColors colors;
  final VoidCallback onCopy;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: NexusColors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: NexusColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_outlined, size: 16, color: colors.textSecondary),
            onPressed: onCopy,
            tooltip: 'Copy',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      );
}
