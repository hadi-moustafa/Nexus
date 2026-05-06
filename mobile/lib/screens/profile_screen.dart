import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';
import '../services/user_service.dart';
import '../services/stripe_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'article_screen.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDark;
  final UserProfile? currentUser;
  final VoidCallback? onSignOut;

  const ProfileScreen({
    super.key,
    required this.isDark,
    this.currentUser,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserStats? _stats;
  List<BookmarkedArticle> _bookmarks = [];
  SubscriptionStatus? _subscription;
  bool _loadingStats = true;
  bool _loadingBookmarks = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _loadStats();
    _loadBookmarks();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await StripeService.instance.fetchSubscription();
      if (mounted) setState(() => _subscription = sub);
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final stats = await UserService.instance.fetchStats();
      if (mounted) setState(() { _stats = stats; _loadingStats = false; });
    } catch (_) {
      if (mounted) setState(() { _stats = UserStats.empty; _loadingStats = false; });
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final result = await UserService.instance.fetchBookmarks(limit: 5);
      if (mounted) setState(() { _bookmarks = result.bookmarks; _loadingBookmarks = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingBookmarks = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: NexusColors.teal,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: colors.background,
              elevation: 0,
              title: Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              actions: [
                if (widget.onSignOut != null)
                  IconButton(
                    icon: Icon(Icons.logout_outlined, color: colors.textPrimary),
                    tooltip: 'Sign out',
                    onPressed: widget.onSignOut,
                  ),
                IconButton(
                  icon: Icon(Icons.workspace_premium_outlined,
                      color: _subscription?.isPremium == true
                          ? NexusColors.amber
                          : colors.textPrimary),
                  tooltip: 'Premium',
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PremiumScreen(isDark: widget.isDark),
                    ));
                    _loadSubscription();
                  },
                ),
              ],
            ),

            // Profile Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: NexusColors.teal.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: NexusColors.teal, width: 3),
                      ),
                      child: widget.currentUser?.avatarUrl != null
                          ? ClipOval(
                              child: Image.network(
                                widget.currentUser!.avatarUrl!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _avatarInitials(),
                              ),
                            )
                          : _avatarInitials(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.currentUser?.name ?? 'Guest',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.currentUser?.email ?? '',
                      style: TextStyle(fontSize: 15, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

            // Premium banner (upgrade CTA or active badge)
            if (_subscription != null && _subscription!.isPremium)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: NexusColors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NexusColors.amber.withOpacity(0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.stars, color: NexusColors.amber, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Premium Member',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: NexusColors.amber,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_subscription == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PremiumScreen(isDark: widget.isDark),
                      ));
                      _loadSubscription();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: NexusColors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NexusColors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_outlined,
                              color: NexusColors.teal, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Upgrade to Premium',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: NexusColors.teal, size: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _loadingStats
                    ? _StatsSkeleton(colors: colors)
                    : _StatsRow(stats: _stats!, isDark: widget.isDark),
              ),
            ),

            // Bookmarks section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Text(
                  'Saved Articles',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),

            // Bookmarks list
            if (_loadingBookmarks)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => _BookmarkSkeleton(colors: colors),
                    childCount: 3,
                  ),
                ),
              )
            else if (_bookmarks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Text(
                    'No saved articles yet.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _BookmarkCard(
                      bookmark: _bookmarks[i],
                      colors: colors,
                    ),
                    childCount: _bookmarks.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _avatarInitials() {
    return Center(
      child: Text(
        widget.currentUser?.initials ?? '?',
        style: const TextStyle(
          fontFamily: 'Fraunces',
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: NexusColors.teal,
        ),
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserStats stats;
  final bool isDark;
  const _StatsRow({required this.stats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Articles Read', value: stats.articlesRead.toString(), isDark: isDark),
          Container(width: 1, height: 40, color: colors.border),
          _StatItem(label: 'Total XP', value: _fmt(stats.totalXp), isDark: isDark),
          Container(width: 1, height: 40, color: colors.border),
          _StatItem(label: 'Day Streak', value: stats.currentStreak.toString(), isDark: isDark),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _StatItem({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: NexusColors.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _StatsSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(3, (i) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 48, height: 24, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(width: 64, height: 12, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
          ],
        )),
      ),
    );
  }
}

// ── Bookmark card ─────────────────────────────────────────────────────────────

class _BookmarkCard extends StatelessWidget {
  final BookmarkedArticle bookmark;
  final DynamicColors colors;
  const _BookmarkCard({required this.bookmark, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: bookmark.article != null
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ArticleScreen(
                  article: bookmark.article!,
                  isDark: colors.isDark,
                  isBookmarked: true,
                ),
              ))
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: bookmark.imageUrl != null && bookmark.imageUrl!.isNotEmpty
                  ? Image.network(
                      bookmark.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bookmark.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bookmark.displaySource,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                              color: colors.textSecondary,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(
                        timeAgo(bookmark.publishedAt),
                        style:
                            TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.bookmark, color: NexusColors.amber, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 60,
      height: 60,
      color: colors.muted,
      child: Icon(Icons.article, color: colors.textSecondary, size: 24),
    );
  }
}

class _BookmarkSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _BookmarkSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(width: 60, height: 60,
              decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(width: 160, height: 14, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(width: 100, height: 12, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
