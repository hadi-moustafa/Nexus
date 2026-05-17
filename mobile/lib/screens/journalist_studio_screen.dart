import 'package:flutter/material.dart';
import '../models/journalist_post.dart';
import '../services/journalist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'journalist_post_screen.dart';

const _badgeMeta = {
  'rising_star': ('⭐', 'Rising Star'),
  'popular':     ('🔥', 'Popular'),
  'gold':        ('🏆', 'Gold'),
  'prolific':    ('📝', 'Prolific'),
  'verified':    ('✓',  'Verified'),
  'featured':    ('★',  'Featured'),
};

const _categories = ['general', 'politics', 'tech', 'business', 'sports', 'science', 'health', 'entertainment'];

class JournalistStudioScreen extends StatefulWidget {
  final bool isDark;

  const JournalistStudioScreen({super.key, required this.isDark});

  @override
  State<JournalistStudioScreen> createState() => _JournalistStudioScreenState();
}

class _JournalistStudioScreenState extends State<JournalistStudioScreen> {
  JournalistProfile? _profile;
  bool _loading = true;
  bool _showCompose = false;

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _selectedCategory = 'general';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
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

  Future<void> _submitPost() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final post = await JournalistService.instance.createPost(
        title: title,
        body: body,
        imageUrl: _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        category: _selectedCategory,
      );
      if (mounted) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        _imageCtrl.clear();
        setState(() {
          _showCompose = false;
          // Prepend to recent posts
          if (_profile != null) {
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
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post published!')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish post')),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
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
              postCount: (_profile!.postCount - 1).clamp(0, 9999),
              badges: _profile!.badges,
              recentPosts: _profile!.recentPosts.where((p) => p.id != postId).toList(),
            );
          }
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete post')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2))
            : _profile == null
                ? _ErrorView(colors: colors, onRetry: _load)
                : RefreshIndicator(
                    color: NexusColors.teal,
                    onRefresh: _load,
                    child: CustomScrollView(
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('Studio',
                                      style: TextStyle(
                                        fontFamily: 'Fraunces',
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textPrimary,
                                      )),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _showCompose = !_showCompose),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: NexusColors.teal,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(_showCompose ? Icons.close : Icons.add, color: Colors.white, size: 18),
                                        const SizedBox(width: 6),
                                        Text(_showCompose ? 'Cancel' : 'New post',
                                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Profile card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: _ProfileCard(profile: _profile!, colors: colors),
                          ),
                        ),

                        // Compose form
                        if (_showCompose)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: _ComposeCard(
                                titleCtrl: _titleCtrl,
                                bodyCtrl: _bodyCtrl,
                                imageCtrl: _imageCtrl,
                                selectedCategory: _selectedCategory,
                                onCategoryChanged: (c) => setState(() => _selectedCategory = c),
                                onSubmit: _submitPost,
                                submitting: _submitting,
                                colors: colors,
                              ),
                            ),
                          ),

                        // Posts header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Text('Your Posts',
                                style: TextStyle(
                                  fontFamily: 'Fraunces',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                )),
                          ),
                        ),

                        // Posts list
                        _profile!.recentPosts.isEmpty
                            ? SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                                  child: Center(
                                    child: Text('No posts yet. Tap "New post" to get started.',
                                        style: TextStyle(color: colors.textSecondary),
                                        textAlign: TextAlign.center),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (_, i) => _PostManageCard(
                                      post: _profile!.recentPosts[i],
                                      isDark: widget.isDark,
                                      colors: colors,
                                      onDelete: () => _deletePost(_profile!.recentPosts[i].id),
                                      onTap: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => JournalistPostScreen(post: _profile!.recentPosts[i], isDark: widget.isDark),
                                      )),
                                    ),
                                    childCount: _profile!.recentPosts.length,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final JournalistProfile profile;
  final DynamicColors colors;
  const _ProfileCard({required this.profile, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: NexusColors.teal.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: profile.avatarUrl != null
                    ? ClipOval(child: Image.network(profile.avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initial(profile.name)))
                    : _initial(profile.name),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(profile.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: colors.textPrimary)),
                        if (profile.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, color: NexusColors.teal, size: 16),
                        ],
                      ],
                    ),
                    if (profile.bio != null)
                      Text(profile.bio!, style: TextStyle(fontSize: 13, color: colors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(label: 'Followers', value: profile.followerCount.toString(), colors: colors),
              Container(width: 1, height: 28, color: colors.border, margin: const EdgeInsets.symmetric(horizontal: 16)),
              _Stat(label: 'Posts', value: profile.postCount.toString(), colors: colors),
            ],
          ),
          if (profile.badges.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.badges.map((b) {
                final meta = _badgeMeta[b['badge_type']];
                if (meta == null) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NexusColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: NexusColors.teal.withOpacity(0.3)),
                  ),
                  child: Text('${meta.$1} ${meta.$2}',
                      style: const TextStyle(fontSize: 12, color: NexusColors.teal, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _initial(String name) => Center(
    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(fontFamily: 'Fraunces', fontSize: 22, fontWeight: FontWeight.w700, color: NexusColors.teal)),
  );
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final DynamicColors colors;
  const _Stat({required this.label, required this.value, required this.colors});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 20, fontWeight: FontWeight.w700, color: NexusColors.teal)),
      Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
    ],
  );
}

class _ComposeCard extends StatelessWidget {
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final TextEditingController imageCtrl;
  final String selectedCategory;
  final void Function(String) onCategoryChanged;
  final VoidCallback onSubmit;
  final bool submitting;
  final DynamicColors colors;

  const _ComposeCard({
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.imageCtrl,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onSubmit,
    required this.submitting,
    required this.colors,
  });

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
    filled: true,
    fillColor: colors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: NexusColors.teal)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexusColors.teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New Post', style: TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
          const SizedBox(height: 12),
          TextField(controller: titleCtrl, style: TextStyle(color: colors.textPrimary, fontSize: 15), decoration: _dec('Title *'), maxLength: 200),
          const SizedBox(height: 8),
          TextField(controller: bodyCtrl, style: TextStyle(color: colors.textPrimary, fontSize: 14), decoration: _dec('Body *'), maxLines: 6, maxLength: 10000),
          const SizedBox(height: 8),
          TextField(controller: imageCtrl, style: TextStyle(color: colors.textPrimary, fontSize: 14), decoration: _dec('Image URL (optional)')),
          const SizedBox(height: 10),
          // Category picker
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((cat) {
                final selected = cat == selectedCategory;
                return GestureDetector(
                  onTap: () => onCategoryChanged(cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? NexusColors.teal : colors.muted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : colors.textSecondary,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: submitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: NexusColors.teal,
              disabledBackgroundColor: NexusColors.teal.withOpacity(0.4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Publish', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }
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
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(post.imageUrl!, width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder()),
              )
            else
              _placeholder(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MetaChip(icon: Icons.chat_bubble_outline, label: post.commentCount.toString(), colors: colors),
                      const SizedBox(width: 10),
                      _MetaChip(icon: Icons.favorite_outline, label: post.reactionCount.toString(), colors: colors),
                      const SizedBox(width: 10),
                      _MetaChip(icon: Icons.visibility_outlined, label: post.viewCount.toString(), colors: colors),
                      const Spacer(),
                      Text(timeAgo(post.createdAt), style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red.withOpacity(0.7),
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
    width: 56, height: 56,
    decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(8)),
    child: Icon(Icons.article, color: colors.textSecondary, size: 24),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final DynamicColors colors;
  const _MetaChip({required this.icon, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: colors.textSecondary),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
    ],
  );
}

class _ErrorView extends StatelessWidget {
  final DynamicColors colors;
  final VoidCallback onRetry;
  const _ErrorView({required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_outlined, size: 48, color: colors.textSecondary),
          const SizedBox(height: 12),
          Text('No journalist profile linked to your account.',
              style: TextStyle(color: colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
