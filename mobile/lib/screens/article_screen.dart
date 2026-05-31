import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article.dart';
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
  late bool _bookmarked;
  bool _bookmarkLoading = false;

  @override
  void initState() {
    super.initState();
    _bookmarked = widget.isBookmarked;
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkLoading) return;
    final wasBookmarked = _bookmarked;
    // Optimistic update
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
            content: const Text('Bookmark limit reached. Upgrade to Premium for unlimited bookmarks.'),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PremiumScreen(isDark: widget.isDark),
                ),
              ),
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
      // Revert on failure
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

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(widget.article.url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article')),
        );
      }
    }
  }

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
                          strokeWidth: 2,
                          color: NexusColors.amber,
                        ),
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
                        style:
                            TextStyle(fontSize: 13, color: colors.textSecondary),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
