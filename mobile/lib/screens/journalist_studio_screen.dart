import 'package:flutter/material.dart';
import '../models/journalist_post.dart';
import '../services/journalist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/owl_mascot.dart';
import 'journalist_post_screen.dart';

const _badgeMeta = {
  'rising_star': ('⭐', 'Rising Star'),
  'popular':     ('🔥', 'Popular'),
  'gold':        ('🏆', 'Gold'),
  'prolific':    ('✍️', 'Prolific'),
  'verified':    ('✅', 'Verified'),
  'featured':    ('💎', 'Featured'),
};

const _categories = [
  'general', 'politics', 'tech', 'business',
  'sports', 'science', 'health', 'entertainment',
];

const _catColors = {
  'general':       Color(0xFF6B7280),
  'politics':      Color(0xFF3B82F6),
  'tech':          Color(0xFF8B5CF6),
  'business':      Color(0xFF10B981),
  'sports':        Color(0xFFF59E0B),
  'science':       Color(0xFF06B6D4),
  'health':        Color(0xFFEF4444),
  'entertainment': Color(0xFFF97316),
};

class JournalistStudioScreen extends StatefulWidget {
  final bool isDark;
  const JournalistStudioScreen({super.key, required this.isDark});

  @override
  State<JournalistStudioScreen> createState() => _JournalistStudioScreenState();
}

class _JournalistStudioScreenState extends State<JournalistStudioScreen> {
  JournalistProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await JournalistService.instance.fetchMyProfile();
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCompose() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComposeSheet(
        isDark: widget.isDark,
        onPublished: (post) {
          if (_profile != null) {
            setState(() {
              _profile = JournalistProfile(
                id: _profile!.id,
                name: _profile!.name,
                bio: _profile!.bio,
                avatarUrl: _profile!.avatarUrl,
                isVerified: _profile!.isVerified,
                followerCount: _profile!.followerCount,
                postCount: _profile!.postCount + 1,
                badges: _profile!.badges,
                recentPosts: [post, ..._profile!.recentPosts],
              );
            });
          }
        },
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await JournalistService.instance.deletePost(postId);
      if (mounted) {
        setState(() {
          if (_profile != null) {
            _profile = JournalistProfile(
              id: _profile!.id,
              name: _profile!.name,
              bio: _profile!.bio,
              avatarUrl: _profile!.avatarUrl,
              isVerified: _profile!.isVerified,
              followerCount: _profile!.followerCount,
              postCount: (_profile!.postCount - 1).clamp(0, 99999),
              badges: _profile!.badges,
              recentPosts: _profile!.recentPosts.where((p) => p.id != postId).toList(),
            );
          }
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(children: [
      _loading
          ? const Center(child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2))
          : _profile == null
              ? _ErrorView(colors: colors, onRetry: _load)
              : RefreshIndicator(
                  color: NexusColors.teal,
                  onRefresh: _load,
                  child: CustomScrollView(
                    slivers: [
                      // ── Gradient header ──────────────────────────────────
                      SliverAppBar(
                        expandedHeight: 200,
                        pinned: true,
                        backgroundColor: const Color(0xFF0A1628),
                        elevation: 0,
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
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        // Avatar
                                        _Avatar(name: _profile!.name, url: _profile!.avatarUrl, size: 54),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      _profile!.name,
                                                      style: const TextStyle(
                                                        fontFamily: 'Fraunces',
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w700,
                                                        color: Colors.white,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (_profile!.isVerified) ...[
                                                    const SizedBox(width: 6),
                                                    const Icon(Icons.verified, color: NexusColors.teal, size: 16),
                                                  ],
                                                ],
                                              ),
                                              if (_profile!.bio != null && _profile!.bio!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  _profile!.bio!,
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white.withOpacity(0.6)),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    // Stats row
                                    Row(
                                      children: [
                                        _HeaderStat(value: _profile!.followerCount, label: 'Followers'),
                                        const SizedBox(width: 24),
                                        _HeaderStat(value: _profile!.postCount, label: 'Posts'),
                                        const SizedBox(width: 24),
                                        _HeaderStat(value: _profile!.badges.length, label: 'Badges'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          titlePadding: EdgeInsets.zero,
                        ),
                        title: const Text(
                          'Studio',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // ── Badges ───────────────────────────────────────────
                      if (_profile!.badges.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Badges',
                                    style: TextStyle(
                                      fontFamily: 'Fraunces',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: DynamicColors(widget.isDark).textPrimary,
                                    )),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _profile!.badges.map((b) {
                                    final meta = _badgeMeta[b['badge_type']];
                                    if (meta == null) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: NexusColors.teal.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: NexusColors.teal.withOpacity(0.3)),
                                      ),
                                      child: Text('${meta.$1} ${meta.$2}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: NexusColors.teal,
                                              fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // ── Posts header ─────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Text('Your Posts',
                              style: TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: DynamicColors(widget.isDark).textPrimary,
                              )),
                        ),
                      ),

                      // ── Posts list ───────────────────────────────────────
                      if (_profile!.recentPosts.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                OwlMascot(size: 80, mood: OwlMood.thinking),
                                const SizedBox(height: 16),
                                Text(
                                  'No posts yet.',
                                  style: TextStyle(
                                    fontFamily: 'Fraunces',
                                    fontSize: 18,
                                    color: DynamicColors(widget.isDark).textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap "New Post" to publish your first story.',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: DynamicColors(widget.isDark).textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _PostManageCard(
                                post: _profile!.recentPosts[i],
                                isDark: widget.isDark,
                                colors: DynamicColors(widget.isDark),
                                onDelete: () => _deletePost(_profile!.recentPosts[i].id),
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
                    ],
                  ),
                ),
        // FAB positioned above floating nav bar
        if (!_loading && _profile != null)
          Positioned(
            right: 16,
            bottom: bottomInset + 82,
            child: FloatingActionButton.extended(
              onPressed: _openCompose,
              backgroundColor: NexusColors.teal,
              elevation: 4,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text('New Post',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
    );
  }
}

// ── Compose bottom sheet ───────────────────────────────────────────────────────

class _ComposeSheet extends StatefulWidget {
  final bool isDark;
  final void Function(JournalistPost) onPublished;

  const _ComposeSheet({required this.isDark, required this.onPublished});

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _category = 'general';
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final post = await JournalistService.instance.createPost(
        title: title,
        body: body,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        category: _category,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onPublished(post);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Post published!'),
            backgroundColor: NexusColors.teal,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish. Try again.')),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  InputDecoration _dec(String hint, {String? counterText}) => InputDecoration(
        hintText: hint,
        counterText: counterText,
        hintStyle:
            TextStyle(color: DynamicColors(widget.isDark).textSecondary, fontSize: 14),
        filled: true,
        fillColor: DynamicColors(widget.isDark).background,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DynamicColors(widget.isDark).border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DynamicColors(widget.isDark).border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NexusColors.teal, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text('New Post',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    )),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Form (scrollable)
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextField(
                    controller: _titleCtrl,
                    style: TextStyle(color: colors.textPrimary, fontSize: 15),
                    decoration: _dec('Title *'),
                    maxLength: 200,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        Text('$currentLength/$maxLength',
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary)),
                  ),
                  const SizedBox(height: 12),

                  // Body
                  TextField(
                    controller: _bodyCtrl,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14, height: 1.55),
                    decoration: _dec('Body — tell your story *'),
                    maxLines: 8,
                    maxLength: 10000,
                    buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
                        Text('$currentLength / $maxLength',
                            style: TextStyle(
                                fontSize: 11, color: colors.textSecondary)),
                  ),
                  const SizedBox(height: 12),

                  // Image URL
                  TextField(
                    controller: _imageCtrl,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: _dec('Image URL (optional)').copyWith(
                      prefixIcon: Icon(Icons.image_outlined, color: colors.textSecondary, size: 18),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),

                  // Category picker
                  Text('Category',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = cat == _category;
                      final color = _catColors[cat] ?? const Color(0xFF6B7280);
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.18)
                                : colors.muted,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? color.withOpacity(0.55)
                                  : colors.border,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: selected ? color : colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Publish button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _publish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexusColors.teal,
                        disabledBackgroundColor:
                            NexusColors.teal.withOpacity(0.4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Publish Story',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final String? url;
  final double size;
  const _Avatar({required this.name, this.url, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NexusColors.teal.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: NexusColors.teal.withOpacity(0.5), width: 2),
        ),
        child: url != null
            ? ClipOval(
                child: Image.network(url!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initial(name)))
            : _initial(name),
      );

  Widget _initial(String name) => Center(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              color: NexusColors.teal,
            )),
      );
}

class _HeaderStat extends StatelessWidget {
  final int value;
  final String label;
  const _HeaderStat({required this.value, required this.label});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_fmt(value),
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: Colors.white.withOpacity(0.6))),
        ],
      );
}

class _PostManageCard extends StatelessWidget {
  final JournalistPost post;
  final bool isDark;
  final DynamicColors colors;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _PostManageCard({
    required this.post,
    required this.isDark,
    required this.colors,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: post.imageUrl != null
                  ? Image.network(
                      post.imageUrl!,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
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
                      _Mini(icon: Icons.visibility_outlined, v: post.viewCount, colors: colors),
                      const SizedBox(width: 12),
                      _Mini(icon: Icons.favorite_outline, v: post.reactionCount, colors: colors),
                      const SizedBox(width: 12),
                      _Mini(icon: Icons.chat_bubble_outline, v: post.commentCount, colors: colors),
                      const Spacer(),
                      Text(timeAgo(post.createdAt),
                          style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
            color: colors.muted, borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.article, color: colors.textSecondary, size: 24),
      );
}

class _Mini extends StatelessWidget {
  final IconData icon;
  final int v;
  final DynamicColors colors;
  const _Mini({required this.icon, required this.v, required this.colors});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textSecondary),
          const SizedBox(width: 3),
          Text(v.toString(), style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  final DynamicColors colors;
  final VoidCallback onRetry;
  const _ErrorView({required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OwlMascot(size: 80, mood: OwlMood.sad),
            const SizedBox(height: 16),
            Text('No journalist profile found.',
                style: TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 18,
                    color: colors.textPrimary)),
            const SizedBox(height: 6),
            Text('Contact an admin to set up your account.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: NexusColors.teal),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
}
