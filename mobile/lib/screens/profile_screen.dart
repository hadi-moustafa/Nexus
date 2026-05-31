import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/user_stats.dart';
import '../models/journalist_request.dart';
import '../services/user_service.dart';
import '../services/stripe_service.dart';
import '../services/journalist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/owl_mascot.dart';
import 'article_screen.dart';
import 'premium_screen.dart';
import 'leaderboard_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final UserProfile? currentUser;
  final VoidCallback? onSignOut;

  const ProfileScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    this.currentUser,
    this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  UserStats? _stats;
  List<BookmarkedArticle> _bookmarks = [];
  SubscriptionStatus? _subscription;
  JournalistRequest? _journalistRequest;
  bool _loadingStats = true;
  bool _loadingBookmarks = true;
  bool _loadingRequest = false;
  bool _submittingRequest = false;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _loadStats();
    _loadBookmarks();
    _loadSubscription();
    if (widget.currentUser?.isJournalist == false &&
        widget.currentUser?.isBanned == false) {
      _loadJournalistRequest();
    }
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
      final result = await UserService.instance.fetchBookmarks(limit: 20);
      if (mounted) setState(() { _bookmarks = result.bookmarks; _loadingBookmarks = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingBookmarks = false; });
    }
  }

  Future<void> _loadJournalistRequest() async {
    if (mounted) setState(() => _loadingRequest = true);
    try {
      final req = await JournalistService.instance.fetchMyRequest();
      if (mounted) setState(() { _journalistRequest = req; _loadingRequest = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingRequest = false);
    }
  }

  Future<void> _showJournalistRequestDialog() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Become a Journalist', style: TextStyle(fontFamily: 'Fraunces')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us why you want to join Nexus as a journalist. Our team reviews all applications.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Your message (optional)…',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NexusColors.teal),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _submittingRequest = true);
    try {
      final req = await JournalistService.instance.submitRequest(
        message: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
      if (mounted) {
        setState(() { _journalistRequest = req; _submittingRequest = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submittingRequest = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, innerScrolled) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF0A1628),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.leaderboard_outlined, color: Colors.white),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => LeaderboardScreen(isDark: widget.isDark))),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
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
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A1628), Color(0xFF0A3D2E)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            // Avatar
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: NexusColors.teal.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: NexusColors.teal.withOpacity(0.6),
                                    width: 2.5),
                              ),
                              child: widget.currentUser?.avatarUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        widget.currentUser!.avatarUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _initials(),
                                      ),
                                    )
                                  : _initials(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.currentUser?.name ?? 'Guest',
                                    style: const TextStyle(
                                      fontFamily: 'Fraunces',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.currentUser?.email ?? '',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.6)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  // Role badge
                                  _RoleBadge(role: widget.currentUser?.role ?? 'user'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Premium/upgrade row
                        if (_subscription?.isPremium == true)
                          _PremiumBadge()
                        else
                          GestureDetector(
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => PremiumScreen(isDark: widget.isDark)));
                              _loadSubscription();
                            },
                            child: _UpgradeBanner(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                widget.currentUser?.name ?? 'Profile',
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Journalist request banner
          if (widget.currentUser?.isJournalist == false &&
              widget.currentUser?.isBanned == false)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _JournalistRequestBanner(
                  request: _journalistRequest,
                  loading: _loadingRequest || _submittingRequest,
                  onApply: _showJournalistRequestDialog,
                  colors: colors,
                ),
              ),
            ),

          // Stats card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _loadingStats
                  ? _StatsSkeleton(colors: colors)
                  : _StatsRow(stats: _stats!, isDark: widget.isDark),
            ),
          ),

          // Tab bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: NexusColors.teal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Saved Articles'),
                    Tab(text: 'Activity'),
                  ],
                ),
              ),
            ),
          ),
        ],

        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _BookmarksTab(
              loading: _loadingBookmarks,
              bookmarks: _bookmarks,
              colors: colors,
              isDark: widget.isDark,
            ),
            _ActivityTab(stats: _stats, colors: colors),
          ],
        ),
      ),
    );
  }

  Widget _initials() => Center(
        child: Text(
          widget.currentUser?.initials ?? '?',
          style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: NexusColors.teal),
        ),
      );
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final UserStats stats;
  final bool isDark;
  const _StatsRow({required this.stats, required this.isDark});

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Articles Read', value: stats.articlesRead.toString(), isDark: isDark),
          Container(width: 1, height: 36, color: colors.border),
          _StatItem(label: 'Total XP', value: _fmt(stats.totalXp), isDark: isDark),
          Container(width: 1, height: 36, color: colors.border),
          _StatItem(label: 'Day Streak', value: '${stats.currentStreak}🔥', isDark: isDark),
          Container(width: 1, height: 36, color: colors.border),
          _StatItem(label: 'Quizzes', value: stats.quizzesCompleted.toString(), isDark: isDark),
        ],
      ),
    );
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
        Text(value,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: NexusColors.teal,
            )),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _StatsSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Container(
        height: 72,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            4,
            (i) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 36, height: 20, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(width: 52, height: 10, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
        ),
      );
}

// ── Tabs ──────────────────────────────────────────────────────────────────────

class _BookmarksTab extends StatelessWidget {
  final bool loading;
  final List<BookmarkedArticle> bookmarks;
  final DynamicColors colors;
  final bool isDark;

  const _BookmarksTab({
    required this.loading,
    required this.bookmarks,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: List.generate(5, (_) => _BookmarkSkeleton(colors: colors)),
      );
    }
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OwlMascot(size: 80, mood: OwlMood.neutral),
            const SizedBox(height: 12),
            Text('No saved articles yet.',
                style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 16,
                    color: colors.textPrimary)),
            const SizedBox(height: 4),
            Text('Bookmark articles to read them later.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) => _BookmarkCard(
        bookmark: bookmarks[i],
        colors: colors,
        isDark: isDark,
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final UserStats? stats;
  final DynamicColors colors;
  const _ActivityTab({required this.stats, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Center(
          child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2));
    }
    final items = [
      (icon: Icons.auto_stories_outlined, label: 'Articles Read', value: stats!.articlesRead.toString(), color: NexusColors.teal),
      (icon: Icons.quiz_outlined, label: 'Quizzes Completed', value: stats!.quizzesCompleted.toString(), color: const Color(0xFF8B5CF6)),
      (icon: Icons.star_border_rounded, label: 'Perfect Scores', value: stats!.perfectScores.toString(), color: NexusColors.amber),
      (icon: Icons.local_fire_department_outlined, label: 'Current Streak', value: '${stats!.currentStreak} days', color: const Color(0xFFEF4444)),
      (icon: Icons.workspace_premium_outlined, label: 'Total XP', value: stats!.totalXp.toString(), color: const Color(0xFF10B981)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(fontSize: 14, color: colors.textPrimary)),
            ),
            Text(item.value,
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                )),
          ],
        ),
      )).toList(),
    );
  }
}

// ── Bookmark card ─────────────────────────────────────────────────────────────

class _BookmarkCard extends StatelessWidget {
  final BookmarkedArticle bookmark;
  final DynamicColors colors;
  final bool isDark;
  const _BookmarkCard({required this.bookmark, required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: bookmark.article != null
            ? () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ArticleScreen(
                    article: bookmark.article!,
                    isDark: isDark,
                    isBookmarked: true,
                  ),
                ))
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: bookmark.imageUrl != null && bookmark.imageUrl!.isNotEmpty
                    ? Image.network(bookmark.imageUrl!, width: 58, height: 58,
                        fit: BoxFit.cover, errorBuilder: (_, __, ___) => _ph())
                    : _ph(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookmark.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Text(bookmark.displaySource,
                              style: TextStyle(
                                  fontSize: 11, color: colors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                              width: 3, height: 3,
                              decoration: BoxDecoration(
                                  color: colors.textSecondary,
                                  shape: BoxShape.circle)),
                        ),
                        Text(timeAgo(bookmark.publishedAt),
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.bookmark, color: NexusColors.amber, size: 18),
            ],
          ),
        ),
      );

  Widget _ph() => Container(
        width: 58, height: 58,
        decoration: BoxDecoration(
            color: colors.muted, borderRadius: BorderRadius.circular(9)),
        child: Icon(Icons.article, color: colors.textSecondary, size: 22),
      );
}

class _BookmarkSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _BookmarkSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(width: 58, height: 58,
                decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(9))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(width: 120, height: 13, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(width: 80, height: 11, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Banners & helpers ─────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (role) {
      'admin' => (const Color(0xFF3B82F6), 'Admin'),
      'journalist' => (const Color(0xFF8B5CF6), 'Journalist'),
      'banned' => (const Color(0xFFEF4444), 'Banned'),
      _ => (NexusColors.teal, 'Reader'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: NexusColors.amber.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NexusColors.amber.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.stars, color: NexusColors.amber, size: 17),
            SizedBox(width: 6),
            Text('Premium Member',
                style: TextStyle(
                    color: NexusColors.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      );
}

class _UpgradeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium_outlined,
                color: NexusColors.amber, size: 17),
            const SizedBox(width: 6),
            Text('Upgrade to Premium',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios,
                color: NexusColors.amber, size: 12),
          ],
        ),
      );
}

class _JournalistRequestBanner extends StatelessWidget {
  final JournalistRequest? request;
  final bool loading;
  final VoidCallback onApply;
  final DynamicColors colors;

  const _JournalistRequestBanner({
    required this.request,
    required this.loading,
    required this.onApply,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && request == null) return const SizedBox.shrink();

    if (request == null) {
      return _Banner(
        color: Colors.purple,
        icon: Icons.edit_note,
        title: 'Become a Journalist',
        subtitle: 'Apply to publish stories on Nexus',
        onTap: loading ? null : onApply,
        showArrow: true,
        colors: colors,
      );
    }
    if (request!.isPending) {
      return _Banner(
        color: Colors.amber,
        icon: Icons.hourglass_top,
        title: 'Application Pending',
        subtitle: 'Our team is reviewing your request.',
        colors: colors,
      );
    }
    if (request!.isRejected) {
      return _Banner(
        color: Colors.red,
        icon: Icons.cancel_outlined,
        title: 'Application Rejected',
        subtitle: request!.adminNote ?? 'Tap to apply again',
        onTap: loading ? null : onApply,
        showArrow: true,
        colors: colors,
      );
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showArrow;
  final DynamicColors colors;

  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showArrow = false,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontSize: 13)),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 11, color: colors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (showArrow)
                Icon(Icons.arrow_forward_ios, color: color, size: 13),
            ],
          ),
        ),
      );
}
