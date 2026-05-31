import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/journalist_post.dart';
import '../services/journalist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/owl_mascot.dart';
import 'journalist_post_screen.dart';

const _categoryColors = {
  'general':       Color(0xFF6B7280),
  'politics':      Color(0xFF3B82F6),
  'tech':          Color(0xFF8B5CF6),
  'business':      Color(0xFF10B981),
  'sports':        Color(0xFFF59E0B),
  'science':       Color(0xFF06B6D4),
  'health':        Color(0xFFEF4444),
  'entertainment': Color(0xFFF97316),
};

Color _catColor(String cat) =>
    _categoryColors[cat.toLowerCase()] ?? const Color(0xFF6B7280);

class JournalistFeedScreen extends StatefulWidget {
  final bool isDark;
  const JournalistFeedScreen({super.key, required this.isDark});

  @override
  State<JournalistFeedScreen> createState() => _JournalistFeedScreenState();
}

class _JournalistFeedScreenState extends State<JournalistFeedScreen> {
  List<JournalistPost> _posts = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  final _scrollController = ScrollController();
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    _realtimeChannel = Supabase.instance.client
        .channel('feed:journalist_posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'journalist_posts',
          callback: (_) => _onNewPostDetected(),
        )
        .subscribe();
  }

  Future<void> _onNewPostDetected() async {
    try {
      final result = await JournalistService.instance.fetchPosts();
      if (!mounted) return;
      final existingIds = _posts.map((p) => p.id).toSet();
      final fresh = result.posts.where((p) => !existingIds.contains(p.id)).toList();
      if (fresh.isEmpty) return;
      setState(() => _posts.insertAll(0, fresh));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.fiber_new_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('${fresh.length} new post${fresh.length > 1 ? 's' : ''} published'),
            ]),
            backgroundColor: NexusColors.teal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Top',
              textColor: Colors.white,
              onPressed: () => _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
              ),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        _nextCursor != null &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await JournalistService.instance.fetchPosts();
      if (mounted) {
        setState(() {
          _posts = result.posts;
          _nextCursor = result.nextCursor;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await JournalistService.instance.fetchPosts(cursor: _nextCursor);
      if (mounted) {
        setState(() {
          _posts.addAll(result.posts);
          _nextCursor = result.nextCursor;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: colors.background,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: NexusColors.teal.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.newspaper, color: NexusColors.teal, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'Journalist Posts',
                  style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
        body: _loading
            ? _buildSkeletons(colors)
            : _posts.isEmpty
                ? _buildEmpty(colors)
                : RefreshIndicator(
                    color: NexusColors.teal,
                    onRefresh: _load,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      itemCount: _posts.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= _posts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: NexusColors.teal, strokeWidth: 2)),
                            ),
                          );
                        }
                        return _AnimatedPostCard(
                          index: i,
                          post: _posts[i],
                          isDark: widget.isDark,
                          colors: colors,
                          onTap: () => _openPost(_posts[i]),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  void _openPost(JournalistPost post) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, anim, __) =>
            JournalistPostScreen(post: post, isDark: widget.isDark),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: FadeTransition(opacity: anim, child: child),
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildSkeletons(DynamicColors colors) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: List.generate(4, (_) => _PostSkeleton(colors: colors)),
      );

  Widget _buildEmpty(DynamicColors colors) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OwlMascot(size: 96, mood: OwlMood.thinking),
            const SizedBox(height: 16),
            Text('No journalist posts yet.',
                style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 18,
                    color: colors.textPrimary)),
            const SizedBox(height: 6),
            Text('Check back soon for the latest stories.',
                style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          ],
        ),
      );
}

// ── Animated wrapper for staggered entry ──────────────────────────────────────

class _AnimatedPostCard extends StatefulWidget {
  final int index;
  final JournalistPost post;
  final bool isDark;
  final DynamicColors colors;
  final VoidCallback onTap;

  const _AnimatedPostCard({
    required this.index,
    required this.post,
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_AnimatedPostCard> createState() => _AnimatedPostCardState();
}

class _AnimatedPostCardState extends State<_AnimatedPostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: _PostCard(
            post: widget.post,
            isDark: widget.isDark,
            colors: widget.colors,
            onTap: widget.onTap,
          ),
        ),
      );
}

// ── Post card ─────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final JournalistPost post;
  final bool isDark;
  final DynamicColors colors;
  final VoidCallback onTap;

  const _PostCard({
    required this.post,
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _catColor(post.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.28 : 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image with gradient overlay
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Image.network(
                      post.imageUrl!,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                    // Gradient overlay at bottom
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Category chip over image
                    Positioned(
                      top: 12, left: 12,
                      child: _CategoryChip(category: post.category, color: catColor),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip (when no image)
                  if (post.imageUrl == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryChip(category: post.category, color: catColor),
                    ),

                  // Author row
                  Row(
                    children: [
                      _MiniAvatar(name: post.journalistName, avatarUrl: post.journalistAvatarUrl),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.journalistName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (post.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: NexusColors.teal, size: 13),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        timeAgo(post.createdAt),
                        style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    post.title,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Excerpt
                  Text(
                    post.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // Footer stats
                  Row(
                    children: [
                      _StatPill(icon: Icons.favorite_border, value: post.reactionCount, isDark: isDark),
                      const SizedBox(width: 10),
                      _StatPill(icon: Icons.chat_bubble_outline, value: post.commentCount, isDark: isDark),
                      const SizedBox(width: 10),
                      _StatPill(icon: Icons.visibility_outlined, value: post.viewCount, isDark: isDark),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: NexusColors.teal.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('Read', style: TextStyle(fontSize: 11, color: NexusColors.teal, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward, color: NexusColors.teal, size: 11),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String category;
  final Color color;
  const _CategoryChip({required this.category, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(
          category.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _MiniAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _MiniAvatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) => avatarUrl != null
      ? ClipOval(
          child: Image.network(
            avatarUrl!,
            width: 26,
            height: 26,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        )
      : _placeholder();

  Widget _placeholder() => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: NexusColors.teal.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: NexusColors.teal),
          ),
        ),
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final int value;
  final bool isDark;
  const _StatPill({required this.icon, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toString(),
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _PostSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 26, height: 26, decoration: BoxDecoration(color: colors.muted, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Container(height: 12, width: 100, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                    const Spacer(),
                    Container(height: 10, width: 40, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                  ]),
                  const SizedBox(height: 10),
                  Container(height: 20, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 220, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 160, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ],
        ),
      );
}
