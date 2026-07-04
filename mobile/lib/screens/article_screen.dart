import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'premium_screen.dart';

class ArticleScreen extends StatefulWidget {
  final Article article;
  final bool isDark;
  /// Pass true when navigating from a bookmarks list so the icon starts filled.
  final bool isBookmarked;

  const ArticleScreen({
    super.key,
    required this.article,
    required this.isDark,
    this.isBookmarked = false,
  });

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  // ── Bookmark ──────────────────────────────────────────────────────────────
  late bool _bookmarked;
  bool _bookmarkLoading = false;

  // ── Reactions ─────────────────────────────────────────────────────────────
  Map<String, int> _reactionCounts = {};
  String? _myReaction;
  bool _reactionsLoading = true;
  bool _reactionPending = false;

  // ── Comments ──────────────────────────────────────────────────────────────
  List<ArticleComment> _comments = [];
  String? _commentsCursor;
  bool _commentsLoading = true;
  bool _loadingMoreComments = false;
  bool _submittingComment = false;
  String? _commentError;
  final _commentController = TextEditingController();

  String? get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isBookmarked;
    _loadReactions();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ── Loaders ───────────────────────────────────────────────────────────────

  Future<void> _loadReactions() async {
    try {
      final result =
          await ArticlesService.instance.fetchReactions(widget.article.id);
      if (mounted) {
        setState(() {
          _reactionCounts = result.counts;
          _myReaction = result.myReaction;
          _reactionsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reactionsLoading = false);
    }
  }

  Future<void> _loadComments() async {
    try {
      final result =
          await ArticlesService.instance.fetchComments(widget.article.id);
      if (mounted) {
        setState(() {
          _comments = result.comments;
          _commentsCursor = result.nextCursor;
          _commentsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_commentsCursor == null || _loadingMoreComments) return;
    setState(() => _loadingMoreComments = true);
    try {
      final result = await ArticlesService.instance.fetchComments(
        widget.article.id,
        cursor: _commentsCursor,
      );
      if (mounted) {
        setState(() {
          _comments.addAll(result.comments);
          _commentsCursor = result.nextCursor;
          _loadingMoreComments = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMoreComments = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _toggleBookmark() async {
    if (_bookmarkLoading) return;
    final wasBookmarked = _bookmarked;
    setState(() {
      _bookmarked = !wasBookmarked;
      _bookmarkLoading = true;
    });
    try {
      if (wasBookmarked) {
        await UserService.instance.removeBookmark(widget.article.id);
      } else {
        await UserService.instance.addBookmark(widget.article.id);
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _bookmarked = wasBookmarked);
      if (!mounted) return;
      if (e.response?.statusCode == 403) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Bookmark limit reached. Upgrade to Premium for unlimited bookmarks.'),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PremiumScreen(isDark: widget.isDark),
              )),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update bookmark')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _bookmarked = wasBookmarked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update bookmark')),
        );
      }
    } finally {
      if (mounted) setState(() => _bookmarkLoading = false);
    }
  }

  Future<void> _handleReact(String type) async {
    if (_reactionPending || _currentUserId == null) return;
    final prevReaction = _myReaction;
    final prevCounts = Map<String, int>.from(_reactionCounts);

    // Optimistic update
    setState(() {
      _reactionPending = true;
      if (_myReaction == type) {
        _myReaction = null;
        _reactionCounts[type] = (_reactionCounts[type] ?? 1) - 1;
        if (_reactionCounts[type]! <= 0) _reactionCounts.remove(type);
      } else {
        if (_myReaction != null) {
          _reactionCounts[_myReaction!] =
              (_reactionCounts[_myReaction!] ?? 1) - 1;
          if (_reactionCounts[_myReaction!]! <= 0) {
            _reactionCounts.remove(_myReaction!);
          }
        }
        _myReaction = type;
        _reactionCounts[type] = (_reactionCounts[type] ?? 0) + 1;
      }
    });

    try {
      if (prevReaction == type) {
        await ArticlesService.instance.removeReaction(widget.article.id);
      } else {
        await ArticlesService.instance
            .addReaction(widget.article.id, type);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _myReaction = prevReaction;
          _reactionCounts = prevCounts;
        });
      }
    } finally {
      if (mounted) setState(() => _reactionPending = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _submittingComment) return;
    setState(() {
      _submittingComment = true;
      _commentError = null;
    });
    try {
      final comment =
          await ArticlesService.instance.postComment(widget.article.id, text);
      if (mounted) {
        setState(() {
          _comments.insert(0, comment);
          _submittingComment = false;
        });
        _commentController.clear();
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _submittingComment = false;
          _commentError = e.response?.statusCode == 401
              ? 'Sign in to comment.'
              : 'Could not post comment.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submittingComment = false;
          _commentError = 'Could not post comment.';
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ArticlesService.instance
          .deleteComment(widget.article.id, commentId);
      if (mounted) {
        setState(() => _comments.removeWhere((c) => c.id == commentId));
      }
    } catch (_) {}
  }

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(widget.article.url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open article')));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);
    final article = widget.article;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colors.background,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: _bookmarkLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: NexusColors.amber),
                      )
                    : Icon(
                        _bookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: _bookmarked
                            ? NexusColors.amber
                            : colors.textPrimary,
                      ),
                onPressed: _toggleBookmark,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: NexusColors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: NexusColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    article.title,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Source + time
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.newspaper,
                            size: 14, color: colors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          article.displaySource,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo(article.publishedAt),
                        style: TextStyle(
                            fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hero image
                  if (article.imageUrl != null &&
                      article.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        article.imageUrl!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: colors.muted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.image,
                              size: 48, color: colors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Divider(color: colors.border),
                  const SizedBox(height: 20),

                  // Summary / content
                  if (article.summary != null &&
                      article.summary!.isNotEmpty) ...[
                    Text(
                      article.summary!,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textPrimary,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (article.content != null &&
                      article.content!.isNotEmpty) ...[
                    Text(
                      article.content!,
                      style: TextStyle(
                        fontSize: 16,
                        color: colors.textPrimary,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if ((article.summary == null || article.summary!.isEmpty) &&
                      (article.content == null || article.content!.isEmpty)) ...[
                    Text(
                      'No preview available. Read the full article on the source website.',
                      style: TextStyle(
                        fontSize: 15,
                        color: colors.textSecondary,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 8),

                  // Read full article CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NexusColors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text(
                        'Read Full Article',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  // ── Reactions ───────────────────────────────────────────
                  const SizedBox(height: 28),
                  Divider(color: colors.border),
                  const SizedBox(height: 16),

                  Text(
                    'React to this story',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _reactionsLoading
                      ? _ReactionsSkeleton(colors: colors)
                      : _ReactionsBar(
                          counts: _reactionCounts,
                          myReaction: _myReaction,
                          pending: _reactionPending,
                          isLoggedIn: _currentUserId != null,
                          onReact: _handleReact,
                          colors: colors,
                        ),

                  // ── Comments ────────────────────────────────────────────
                  const SizedBox(height: 28),
                  Divider(color: colors.border),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 18, color: NexusColors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      if (_comments.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${_comments.length}${_commentsCursor != null ? '+' : ''})',
                          style: TextStyle(
                              fontSize: 14, color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Comment compose box
                  if (_currentUserId != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                            minLines: 1,
                            maxLength: 1000,
                            style: TextStyle(
                                fontSize: 14, color: colors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Add a comment…',
                              hintStyle:
                                  TextStyle(color: colors.textSecondary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.fromLTRB(
                                  14, 12, 14, 4),
                              counterText: '',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_commentError != null)
                                  Flexible(
                                    child: Text(
                                      _commentError!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.red),
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                TextButton(
                                  onPressed: _submittingComment
                                      ? null
                                      : _submitComment,
                                  style: TextButton.styleFrom(
                                    backgroundColor: NexusColors.teal,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(64, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _submittingComment
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text('Post',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'Sign in to post a comment',
                        style: TextStyle(
                            fontSize: 14, color: colors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Comment list
                  if (_commentsLoading)
                    _CommentsSkeleton(colors: colors)
                  else if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(
                            fontSize: 14, color: colors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Column(
                      children: [
                        ..._comments.map((c) => _CommentTile(
                              comment: c,
                              currentUserId: _currentUserId,
                              colors: colors,
                              onDelete: () => _deleteComment(c.id),
                            )),
                        if (_commentsCursor != null)
                          TextButton(
                            onPressed: _loadingMoreComments
                                ? null
                                : _loadMoreComments,
                            child: _loadingMoreComments
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: NexusColors.teal),
                                  )
                                : Text('Load more comments',
                                    style: TextStyle(
                                        color: NexusColors.teal,
                                        fontSize: 14)),
                          ),
                      ],
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reactions bar ─────────────────────────────────────────────────────────────

class _ReactionsBar extends StatelessWidget {
  final Map<String, int> counts;
  final String? myReaction;
  final bool pending;
  final bool isLoggedIn;
  final void Function(String type) onReact;
  final DynamicColors colors;

  const _ReactionsBar({
    required this.counts,
    required this.myReaction,
    required this.pending,
    required this.isLoggedIn,
    required this.onReact,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kReactionTypes.map((type) {
            final emoji = kReactionEmojis[type] ?? '?';
            final count = counts[type] ?? 0;
            final active = myReaction == type;
            return GestureDetector(
              onTap: isLoggedIn && !pending ? () => onReact(type) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: active
                      ? NexusColors.teal.withValues(alpha: 0.12)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? NexusColors.teal
                        : colors.border,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    if (count > 0) ...[
                      const SizedBox(width: 5),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? NexusColors.teal
                              : colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (total > 0) ...[
          const SizedBox(height: 8),
          Text(
            '$total ${total == 1 ? 'reaction' : 'reactions'}',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _ReactionsSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _ReactionsSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: List.generate(
            5,
            (_) => Container(
                  width: 52,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.muted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                )),
      );
}

// ── Comment tile ──────────────────────────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final ArticleComment comment;
  final String? currentUserId;
  final DynamicColors colors;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.currentUserId,
    required this.colors,
    required this.onDelete,
  });

  String _relativeTime(String iso) {
    final diff = DateTime.now().difference(DateTime.parse(iso));
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = comment.authorId == currentUserId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: NexusColors.teal,
              shape: BoxShape.circle,
            ),
            child: comment.authorAvatar != null
                ? ClipOval(
                    child: Image.network(comment.authorAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials()))
                : _initials(),
          ),
          const SizedBox(width: 10),
          // Body
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOwn ? 'You' : comment.authorName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _relativeTime(comment.createdAt),
                      style: TextStyle(
                          fontSize: 12, color: colors.textSecondary),
                    ),
                    if (comment.editedAt != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '· edited',
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (isOwn)
            GestureDetector(
              onTap: onDelete,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.delete_outline,
                    size: 16, color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initials() => Center(
        child: Text(
          comment.authorName.isNotEmpty
              ? comment.authorName[0].toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}

class _CommentsSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _CommentsSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: colors.muted, shape: BoxShape.circle),
                ),
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
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 160,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
