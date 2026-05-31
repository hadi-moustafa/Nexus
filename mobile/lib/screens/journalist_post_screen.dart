import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  Map<String, int> _reactionCounts = {
    'like': 0, 'love': 0, 'wow': 0, 'sad': 0, 'angry': 0
  };
  String? _myReaction;
  String? _nextCommentCursor;
  bool _loadingComments = true;
  bool _loadingReactions = true;
  bool _submittingComment = false;
  bool _reactingTo = false;
  bool _showReactionPicker = false;
  bool _isBookmarked = false;
  bool _togglingBookmark = false;
  double _readProgress = 0;
  RealtimeChannel? _reactionChannel;
  RealtimeChannel? _commentChannel;

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadReactions();
    _loadBookmark();
    _scrollController.addListener(_onScroll);
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final postId = widget.post.id;

    _reactionChannel = Supabase.instance.client
        .channel('reactions:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_reactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (_) => _loadReactions(),
        )
        .subscribe();

    _commentChannel = Supabase.instance.client
        .channel('comments:$postId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'post_comments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: postId,
          ),
          callback: (payload) {
            final myId = Supabase.instance.client.auth.currentUser?.id;
            // post_comments uses author_id, not user_id
            final authorId = payload.newRecord['author_id'] as String?;
            if (myId != null && myId == authorId) return;
            _fetchNewComments();
          },
        )
        .subscribe();
  }

  Future<void> _fetchNewComments() async {
    try {
      final result = await JournalistService.instance.fetchComments(widget.post.id);
      if (!mounted) return;
      final existingIds = _comments.map((c) => c.id).toSet();
      final fresh = result.comments.where((c) => !existingIds.contains(c.id)).toList();
      if (fresh.isNotEmpty) setState(() => _comments.insertAll(0, fresh));
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_reactionChannel != null) {
      Supabase.instance.client.removeChannel(_reactionChannel!);
    }
    if (_commentChannel != null) {
      Supabase.instance.client.removeChannel(_commentChannel!);
    }
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.maxScrollExtent > 0) {
      final progress = (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
      if ((progress - _readProgress).abs() > 0.01) {
        setState(() => _readProgress = progress);
      }
    }
    if (pos.pixels >= pos.maxScrollExtent - 200 &&
        _nextCommentCursor != null &&
        !_loadingComments) {
      _loadMoreComments();
    }
  }

  Future<void> _loadBookmark() async {
    try {
      final v = await JournalistService.instance.checkPostBookmark(widget.post.id);
      if (mounted) setState(() => _isBookmarked = v);
    } catch (_) {}
  }

  Future<void> _toggleBookmark() async {
    if (_togglingBookmark) return;
    setState(() {
      _togglingBookmark = true;
      _isBookmarked = !_isBookmarked;
    });
    try {
      final v = await JournalistService.instance.togglePostBookmark(widget.post.id);
      if (mounted) setState(() => _isBookmarked = v);
    } catch (_) {
      if (mounted) setState(() => _isBookmarked = !_isBookmarked);
    } finally {
      if (mounted) setState(() => _togglingBookmark = false);
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
      if (mounted) setState(() { _myReaction = prev; });
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
    final catColor = _catColor(widget.post.category);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          // Reading progress bar + transparent app bar
          Stack(
            children: [
              // App bar
              SafeArea(
                child: Container(
                  height: 56,
                  color: colors.background,
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            widget.post.journalistAvatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      widget.post.journalistAvatarUrl!,
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _AvatarPlaceholder(
                                              name: widget.post.journalistName,
                                              size: 30),
                                    ),
                                  )
                                : _AvatarPlaceholder(
                                    name: widget.post.journalistName, size: 30),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          widget.post.journalistName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (widget.post.isVerified) ...[
                                        const SizedBox(width: 3),
                                        const Icon(Icons.verified,
                                            color: NexusColors.teal, size: 13),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    timeAgo(widget.post.createdAt),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: colors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: _isBookmarked ? NexusColors.teal : colors.textSecondary,
                        ),
                        onPressed: _toggleBookmark,
                      ),
                    ],
                  ),
                ),
              ),
              // Reading progress bar
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: LinearProgressIndicator(
                  value: _readProgress,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(catColor),
                  minHeight: 2,
                ),
              ),
            ],
          ),

          // Content
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: catColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          widget.post.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        widget.post.title,
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Hero image
                      if (widget.post.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.post.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Body
                      Text(
                        widget.post.body,
                        style: TextStyle(
                          fontSize: 16,
                          color: colors.textPrimary,
                          height: 1.75,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Divider
                      Divider(color: colors.border),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 28),

                      // Comments section
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (_loadingComments && _comments.isEmpty)
                        ...List.generate(3, (_) => _CommentSkeleton(colors: colors))
                      else if (_comments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(color: colors.textSecondary, fontSize: 14),
                          ),
                        )
                      else
                        ..._comments.map((c) => _CommentTile(comment: c, colors: colors)),

                      if (_loadingComments && _comments.isNotEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: NexusColors.teal, strokeWidth: 2),
                          ),
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),

                // Comment input bar
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 12),
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
                            hintStyle: TextStyle(
                                color: colors.textSecondary, fontSize: 14),
                            filled: true,
                            fillColor: colors.background,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide(color: colors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: const BorderSide(color: NexusColors.teal),
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _submitComment,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _submittingComment
                                ? colors.muted
                                : NexusColors.teal,
                            shape: BoxShape.circle,
                          ),
                          child: _submittingComment
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 18),
                        ),
                      ),
                    ],
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

// ── Reaction summary ──────────────────────────────────────────────────────────

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
    final topReactions = _reactionEmojis.entries
        .where((e) => (counts[e.key] ?? 0) > 0)
        .toList()
      ..sort((a, b) => (counts[b.key] ?? 0).compareTo(counts[a.key] ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onTogglePicker,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: myReaction != null
                      ? NexusColors.teal.withOpacity(0.12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: myReaction != null
                        ? NexusColors.teal.withOpacity(0.45)
                        : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      myReaction != null
                          ? (_reactionEmojis[myReaction] ?? '👍')
                          : '👍',
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (total > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        total.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: myReaction != null
                              ? NexusColors.teal
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            ...topReactions.take(3).map((e) => Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Text(_reactionEmojis[e.key] ?? '',
                      style: const TextStyle(fontSize: 18)),
                )),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 16, color: colors.textSecondary),
                const SizedBox(width: 4),
                Text(commentCount.toString(),
                    style: TextStyle(fontSize: 13, color: colors.textSecondary)),
              ],
            ),
          ],
        ),

        if (showPicker)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reactionEmojis.entries.map((e) {
                final isActive = myReaction == e.key;
                return GestureDetector(
                  onTap: () => onReact(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? NexusColors.teal.withOpacity(0.14)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isActive
                            ? NexusColors.teal.withOpacity(0.5)
                            : colors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.value, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 5),
                        Text(
                          (counts[e.key] ?? 0).toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? NexusColors.teal
                                : colors.textSecondary,
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

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final DynamicColors colors;
  const _CommentTile({required this.comment, required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
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
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary)),
                      const Spacer(),
                      Text(timeAgo(comment.createdAt),
                          style: TextStyle(
                              fontSize: 11, color: colors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(comment.body,
                        style: TextStyle(
                            fontSize: 14,
                            color: colors.textPrimary,
                            height: 1.45)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _AvatarPlaceholder extends StatelessWidget {
  final String name;
  final double size;
  const _AvatarPlaceholder({required this.name, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: NexusColors.teal.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
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
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: colors.muted, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      );
}
