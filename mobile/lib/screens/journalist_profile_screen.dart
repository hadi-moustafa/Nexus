import 'package:flutter/material.dart';
import '../models/journalist_post.dart';
import '../models/user_profile.dart';
import '../services/journalist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'journalist_post_screen.dart';
import 'journalist_studio_screen.dart';
import 'settings_screen.dart';

const _badgeInfo = {
  'rising_star':  (emoji: '⭐', label: 'Rising Star',  color: Color(0xFFF59E0B)),
  'popular':      (emoji: '🔥', label: 'Popular',      color: Color(0xFFEF4444)),
  'gold':         (emoji: '🥇', label: 'Gold',         color: Color(0xFFD97706)),
  'prolific':     (emoji: '✍️', label: 'Prolific',     color: Color(0xFF8B5CF6)),
  'verified':     (emoji: '✅', label: 'Verified',     color: Color(0xFF10B981)),
  'featured':     (emoji: '💎', label: 'Featured',     color: Color(0xFF06B6D4)),
};

class JournalistProfileScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final UserProfile currentUser;
  final VoidCallback? onSignOut;

  const JournalistProfileScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.currentUser,
    this.onSignOut,
  });

  @override
  State<JournalistProfileScreen> createState() => _JournalistProfileScreenState();
}

class _JournalistProfileScreenState extends State<JournalistProfileScreen> {
  JournalistProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final profile = await JournalistService.instance.fetchMyProfile();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: NexusColors.teal,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: colors.background,
              elevation: 0,
              title: Text(
                'My Profile',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.edit_note, color: colors.textPrimary),
                  tooltip: 'Studio',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JournalistStudioScreen(isDark: widget.isDark),
                    ),
                  ).then((_) => _load()),
                ),
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        isDark: widget.isDark,
                        onToggleTheme: widget.onToggleTheme,
                        onSignOut: widget.onSignOut ?? () {},
                        currentUser: widget.currentUser,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator(color: NexusColors.teal)),
                ),
              )
            else if (_error != null || _profile == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colors.textSecondary),
                      const SizedBox(height: 12),
                      Text('Could not load profile.', style: TextStyle(color: colors.textSecondary)),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              )
            else ...[
              // ── Header card ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: _ProfileHeader(
                    profile: _profile!,
                    colors: colors,
                  ),
                ),
              ),

              // ── Metrics row ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _MetricsRow(profile: _profile!, colors: colors),
                ),
              ),

              // ── Badges ───────────────────────────────────────────────────
              if (_profile!.badges.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _BadgesSection(badges: _profile!.badges, colors: colors),
                  ),
                ),

              // ── Recent posts ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Posts',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JournalistStudioScreen(isDark: widget.isDark),
                          ),
                        ).then((_) => _load()),
                        child: const Text('Manage posts'),
                      ),
                    ],
                  ),
                ),
              ),

              if (_profile!.recentPosts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'No posts yet. Head to the Studio to create your first post.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 14),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _PostMetricCard(
                        post: _profile!.recentPosts[i],
                        colors: colors,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JournalistPostScreen(
                              post: _profile!.recentPosts[i],
                              isDark: widget.isDark,
                            ),
                          ),
                        ),
                      ),
                      childCount: _profile!.recentPosts.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Profile header ─────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final JournalistProfile profile;
  final DynamicColors colors;
  const _ProfileHeader({required this.profile, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: NexusColors.teal.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: profile.isVerified ? NexusColors.teal : colors.border,
                width: profile.isVerified ? 2.5 : 1,
              ),
            ),
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      profile.avatarUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(profile.name),
                    ),
                  )
                : _initials(profile.name),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: NexusColors.teal, size: 18),
                    ],
                  ],
                ),
                if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    profile.bio!,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Journalist',
                    style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: NexusColors.teal,
        ),
      ),
    );
  }
}

// ── Metrics row ────────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  final JournalistProfile profile;
  final DynamicColors colors;
  const _MetricsRow({required this.profile, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(value: _fmt(profile.followerCount), label: 'Followers', colors: colors),
          _divider(colors),
          _Metric(value: _fmt(profile.postCount), label: 'Posts', colors: colors),
          _divider(colors),
          _Metric(
            value: _fmt(_totalViews(profile.recentPosts)),
            label: 'Views',
            colors: colors,
          ),
          _divider(colors),
          _Metric(value: profile.badges.length.toString(), label: 'Badges', colors: colors),
        ],
      ),
    );
  }

  Widget _divider(DynamicColors colors) =>
      Container(width: 1, height: 36, color: colors.border);

  int _totalViews(List<JournalistPost> posts) =>
      posts.fold(0, (sum, p) => sum + p.viewCount);

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final DynamicColors colors;
  const _Metric({required this.value, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: NexusColors.teal,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      ],
    );
  }
}

// ── Badges section ─────────────────────────────────────────────────────────────

class _BadgesSection extends StatelessWidget {
  final List<Map<String, dynamic>> badges;
  final DynamicColors colors;
  const _BadgesSection({required this.badges, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Badges',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: badges.map((b) {
            final type = b['badgeType'] as String? ?? '';
            final info = _badgeInfo[type];
            if (info == null) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: info.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: info.color.withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(info.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    info.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: info.color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Post metric card ───────────────────────────────────────────────────────────

class _PostMetricCard extends StatelessWidget {
  final JournalistPost post;
  final DynamicColors colors;
  final VoidCallback onTap;
  const _PostMetricCard({required this.post, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: NexusColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.category,
                    style: const TextStyle(fontSize: 11, color: NexusColors.teal, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Text(timeAgo(post.createdAt), style: TextStyle(fontSize: 12, color: colors.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Stat(icon: Icons.visibility_outlined, value: post.viewCount, colors: colors),
                const SizedBox(width: 16),
                _Stat(icon: Icons.chat_bubble_outline, value: post.commentCount, colors: colors),
                const SizedBox(width: 16),
                _Stat(icon: Icons.favorite_outline, value: post.reactionCount, colors: colors),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int value;
  final DynamicColors colors;
  const _Stat({required this.icon, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString(),
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ],
    );
  }
}
