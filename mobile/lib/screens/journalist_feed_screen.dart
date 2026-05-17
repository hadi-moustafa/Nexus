import 'package:flutter/material.dart';
import '../models/journalist_post.dart';
import '../services/journalist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'journalist_post_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Journalist Posts',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 4,
                      itemBuilder: (_, __) => _PostSkeleton(colors: colors),
                    )
                  : _posts.isEmpty
                      ? Center(
                          child: Text(
                            'No journalist posts yet.',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        )
                      : RefreshIndicator(
                          color: NexusColors.teal,
                          onRefresh: _load,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                            itemCount: _posts.length + (_loadingMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _posts.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2),
                                  ),
                                );
                              }
                              return _PostCard(
                                post: _posts[i],
                                isDark: widget.isDark,
                                colors: colors,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JournalistPostScreen(post: _posts[i], isDark: widget.isDark),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  Row(
                    children: [
                      _MiniAvatar(name: post.journalistName, avatarUrl: post.journalistAvatarUrl),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(post.journalistName,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                                if (post.isVerified) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, color: NexusColors.teal, size: 13),
                                ],
                              ],
                            ),
                            Text(timeAgo(post.createdAt),
                                style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NexusColors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(post.category,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: NexusColors.teal)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(post.title,
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),

                  // Excerpt
                  Text(post.body,
                      style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),

                  // Footer stats
                  Row(
                    children: [
                      _Stat(icon: Icons.favorite_outline, value: post.reactionCount, colors: colors),
                      const SizedBox(width: 14),
                      _Stat(icon: Icons.chat_bubble_outline, value: post.commentCount, colors: colors),
                      const SizedBox(width: 14),
                      _Stat(icon: Icons.visibility_outlined, value: post.viewCount, colors: colors),
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

class _MiniAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  const _MiniAvatar({required this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) => avatarUrl != null
      ? ClipOval(child: Image.network(avatarUrl!, width: 28, height: 28, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder()))
      : _placeholder();

  Widget _placeholder() => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(color: NexusColors.teal.withOpacity(0.2), shape: BoxShape.circle),
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NexusColors.teal))),
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int value;
  final DynamicColors colors;
  const _Stat({required this.icon, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: colors.textSecondary),
      const SizedBox(width: 4),
      Text(value.toString(), style: TextStyle(fontSize: 12, color: colors.textSecondary)),
    ],
  );
}

class _PostSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _PostSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 180, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(10))),
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: colors.muted, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Container(height: 12, width: 100, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
        ]),
        const SizedBox(height: 10),
        Container(height: 18, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 6),
        Container(height: 14, width: 200, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
      ],
    ),
  );
}
