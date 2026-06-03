import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../utils/time_utils.dart';
import '../widgets/owl_mascot.dart';
import 'article_screen.dart';

class CountryPanel extends StatefulWidget {
  final String regionSlug;
  final String regionName;
  final bool isDark;
  final VoidCallback onClose;

  const CountryPanel({
    super.key,
    required this.regionSlug,
    required this.regionName,
    required this.isDark,
    required this.onClose,
  });

  @override
  State<CountryPanel> createState() => _CountryPanelState();
}

class _CountryPanelState extends State<CountryPanel> {
  List<Article> _articles = [];
  bool _loading = true;
  String? _error;
  String? _nextCursor;
  bool _loadingMore = false;

  static const _regionEmojis = {
    'europe':      '🏛️',
    'asia':        '🏯',
    'middle-east': '🕌',
    'americas':    '🗽',
    'africa':      '🌍',
    'oceania':     '🦘',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ArticlesService.instance
          .fetchArticlesByRegion(widget.regionSlug, limit: 20);
      if (mounted) {
        setState(() {
          _articles = result.articles;
          _nextCursor = result.nextCursor;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load articles'; _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final result = await ArticlesService.instance
          .fetchArticlesByRegion(widget.regionSlug, limit: 20, cursor: _nextCursor);
      if (mounted) {
        setState(() {
          _articles.addAll(result.articles);
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
    final emoji = _regionEmojis[widget.regionSlug] ?? '🌐';

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Handle ────────────────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                child: Row(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.regionName,
                              style: TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              )),
                          Text(
                            _loading
                                ? 'Loading stories…'
                                : _error != null
                                    ? 'Error loading stories'
                                    : '${_articles.length} stories',
                            style: TextStyle(fontSize: 13, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: colors.muted,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: colors.textSecondary, size: 16),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── Article list ──────────────────────────────────────────────
              Expanded(child: _buildBody(colors, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(DynamicColors colors, ScrollController scrollController) {
    if (_loading) {
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: List.generate(5, (_) => _ArticleSkeleton(colors: colors)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OwlMascot(size: 72, mood: OwlMood.sad),
            const SizedBox(height: 16),
            Text(_error!,
                style: TextStyle(fontSize: 14, color: colors.textSecondary)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 16, color: NexusColors.teal),
              label: const Text('Try again',
                  style: TextStyle(color: NexusColors.teal)),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OwlMascot(size: 80, mood: OwlMood.neutral),
            const SizedBox(height: 16),
            Text('No stories right now',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 17,
                  color: colors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text('Check back soon for ${widget.regionName} news.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary)),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        itemCount: _articles.length + (_nextCursor != null ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == _articles.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(
                          color: NexusColors.teal, strokeWidth: 2))
                    : TextButton(
                        onPressed: _loadMore,
                        child: const Text('Load more',
                            style: TextStyle(color: NexusColors.teal))),
              ),
            );
          }
          return _RegionArticleCard(
            article: _articles[i],
            colors: colors,
            isDark: widget.isDark,
          );
        },
      ),
    );
  }
}

// ── Article card ──────────────────────────────────────────────────────────────

class _RegionArticleCard extends StatelessWidget {
  final Article article;
  final DynamicColors colors;
  final bool isDark;

  const _RegionArticleCard({
    required this.article,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ArticleScreen(article: article, isDark: isDark),
        )),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: NexusColors.teal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: NexusColors.teal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(article.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          child: Text(article.displaySource,
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 3, height: 3,
                            decoration: BoxDecoration(
                              color: colors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Text(timeAgo(article.publishedAt),
                            style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              if (article.imageUrl != null && article.imageUrl!.isNotEmpty) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    article.imageUrl!,
                    width: 80, height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _ArticleSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _ArticleSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sh(colors, h: 20, w: 70),
                  const SizedBox(height: 10),
                  _sh(colors, h: 14, w: double.infinity),
                  const SizedBox(height: 6),
                  _sh(colors, h: 14, w: 200),
                  const SizedBox(height: 6),
                  _sh(colors, h: 14, w: 140),
                  const SizedBox(height: 10),
                  _sh(colors, h: 11, w: 100),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      );

  Widget _sh(DynamicColors c, {required double h, required double w}) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Container(
          height: h, width: w,
          decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(4)),
        ),
      );
}
