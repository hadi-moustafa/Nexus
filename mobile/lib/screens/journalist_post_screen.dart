import 'package:flutter/material.dart';
import '../models/journalist_post.dart';
import '../services/journalist_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

const _reactionEmojis = {
  'like': '👍',
  'love': '❤️',
  'wow': '😮',
  'sad': '😢',
  'angry': '😠',
};

class JournalistPostScreen extends StatefulWidget {
  final JournalistPost post;
  final bool isDark;

  const JournalistPostScreen({
    super.key,
    required this.post,
    required this.isDark,
  });

  @override
  State<JournalistPostScreen> createState() => _JournalistPostScreenState();
}

class _JournalistPostScreenState extends State<JournalistPostScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  List<PostComment> _comments = [];
  Map<String, int> _reactionCounts = {'like': 0, 'love': 0, 'wow': 0, 'sad': 0, 'angry': 0};
  String? _myReaction;
  String? _nextCommentCursor;
  bool _loadingComments = true;
  bool _loadingReactions = true;
  bool _submittingComment = false;
  bool _reactingTo = false;
  bool _showReactionPicker = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadReactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        _nextCommentCursor != null &&
        !_loadingComments) {
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    try {
      final result = await JournalistService.instance.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = result.comments;
          _nextCommentCursor = result.nextCursor;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_nextCommentCursor == null) return;
    setState(() => _loadingComments = true);
    try {
      final result = await JournalistService.instance.fetchComments(
        widget.post.id,
        cursor: _nextCommentCursor,
      );
      if (mounted) {
        setState(() {
          _comments.addAll(result.comments);
          _nextCommentCursor = result.nextCursor;
          _loadingComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _loadReactions() async {
    try {
      final result = await JournalistService.instance.fetchReactions(widget.post.id);
      if (mounted) {
        setState(() {
          _reactionCounts = result.counts;
          _myReaction = result.myReaction;
          _loadingReactions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReactions = false);
    }
  }

  Future<void> _toggleReaction(String type) async {
    if (_reactingTo) return;
    setState(() {
      _reactingTo = true;
      _showReactionPicker = false;
    });

    final prev = _myReaction;
    final newCounts = Map<String, int>.from(_reactionCounts);

    // Optimistic update
    if (prev != null) newCounts[prev] = (newCounts[prev] ?? 1) - 1;
    if (prev != type) {
      newCounts[type] = (newCounts[type] ?? 0) + 1;
      setState(() { _myReaction = type; _reactionCounts = newCounts; });
    } else {
      setState(() { _myReaction = null; _reactionCounts = newCounts; });
    }

    try {
      await JournalistService.instance.toggleReaction(widget.post.id, type);
    } catch (_) {
      // Revert on error
      if (mounted) setState(() { _myReaction = prev; _reactionCounts = _reactionCounts; });
    }

    if (mounted) setState(() => _reactingTo = false);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submittingComment) return;
    setState(() => _submittingComment = true);
    try {
      final comment = await JournalistService.instance.addComment(widget.post.id, text);
      if (mounted) {
        _commentController.clear();
        setState(() => _comments.insert(0, comment));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post comment')),
        );
      }
    }
    if (mounted) setState(() => _submittingComment = false);
  }

  int get _totalReactions => _reactionCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (widget.post.journalistAvatarUrl != null)
              ClipOval(
                child: Image.network(widget.post.journalistAvatarUrl!, width: 32, height: 32, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _AvatarPlaceholder(name: widget.post.journalistName, size: 32)),
              )
            else
              _AvatarPlaceholder(name: widget.post.journalistName, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.post.journalistName,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                      if (widget.post.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: NexusColors.teal, size: 14),
                      ],
                    ],
                  ),
                  Text(timeAgo(widget.post.createdAt),
                      style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Post content
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NexusColors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(widget.post.category.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: NexusColors.teal)),
                ),
                const SizedBox(height: 12),

                // Title
                Text(widget.post.title,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      height: 1.3,
                    )),
                const SizedBox(height: 16),

                // Hero image
                if (widget.post.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.post.imageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Body
                Text(widget.post.body,
                    style: TextStyle(fontSize: 16, color: colors.textPrimary, height: 1.6)),
                const SizedBox(height: 24),

                // Reaction bar
                _ReactionSummary(
                  counts: _reactionCounts,
                  myReaction: _myReaction,
                  total: _totalReactions,
                  loading: _loadingReactions,
                  showPicker: _showReactionPicker,
                  onTogglePicker: () => setState(() => _showReactionPicker = !_showReactionPicker),
                  onReact: _toggleReaction,
                  commentCount: widget.post.commentCount,
                  isDark: widget.isDark,
                ),
                const SizedBox(height: 24),

                // Comments header
                Text('Comments',
                    style: TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                const SizedBox(height: 12),

                // Comments
                if (_loadingComments && _comments.isEmpty)
                  ...List.generate(3, (_) => _CommentSkeleton(colors: colors))
                else if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No comments yet. Be the first!',
                        style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                  )
                else
                  ..._comments.map((c) => _CommentTile(comment: c, colors: colors)),

                if (_loadingComments && _comments.isNotEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2),
                  )),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // Comment input
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Write a comment…',
                      hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: colors.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: colors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: colors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: NexusColors.teal)),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _submitComment,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _submittingComment ? colors.muted : NexusColors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: _submittingComment
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reaction summary bar ─────────────────────────────────────────────────────

class _ReactionSummary extends StatelessWidget {
  final Map<String, int> counts;
  final String? myReaction;
  final int total;
  final bool loading;
  final bool showPicker;
  final VoidCallback onTogglePicker;
  final void Function(String) onReact;
  final int commentCount;
  final bool isDark;

  const _ReactionSummary({
    required this.counts,
    required this.myReaction,
    required this.total,
    required this.loading,
    required this.showPicker,
    required this.onTogglePicker,
    required this.onReact,
    required this.commentCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    // Top reactions to display
    final topReactions = _reactionEmojis.entries
        .where((e) => (counts[e.key] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Reaction emoji pill
            GestureDetector(
              onTap: onTogglePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: myReaction != null ? NexusColors.teal.withOpacity(0.1) : colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: myReaction != null ? NexusColors.teal.withOpacity(0.4) : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(myReaction != null ? (_reactionEmojis[myReaction] ?? '👍') : '👍',
                        style: const TextStyle(fontSize: 16)),
                    if (total > 0) ...[
                      const SizedBox(width: 6),
                      Text(total.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: myReaction != null ? NexusColors.teal : colors.textSecondary,
                          )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Top reaction emojis
            ...topReactions.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(_reactionEmojis[e.key] ?? '', style: const TextStyle(fontSize: 18)),
                )),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 16, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(commentCount.toString(),
                    style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              ],
            ),
          ],
        ),
        // Reaction picker
        if (showPicker)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              children: _reactionEmojis.entries.map((e) {
                final isActive = myReaction == e.key;
                return GestureDetector(
                  onTap: () => onReact(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? NexusColors.teal.withOpacity(0.15) : colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isActive ? NexusColors.teal.withOpacity(0.5) : colors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.value, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 4),
                        Text(
                          (counts[e.key] ?? 0).toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? NexusColors.teal : colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

// ── Comment tile ─────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final DynamicColors colors;

  const _CommentTile({required this.comment, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarPlaceholder(name: comment.authorName, size: 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                    const Spacer(),
                    Text(timeAgo(comment.createdAt),
                        style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(comment.body,
                      style: TextStyle(fontSize: 14, color: colors.textPrimary, height: 1.4)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  final double size;
  const _AvatarPlaceholder({required this.name, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NexusColors.teal.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: size * 0.4,
              fontWeight: FontWeight.w600,
              color: NexusColors.teal,
            ),
          ),
        ),
      );
}

class _CommentSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _CommentSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 34, height: 34, decoration: BoxDecoration(color: colors.muted, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, width: 80, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 48, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      );
}
