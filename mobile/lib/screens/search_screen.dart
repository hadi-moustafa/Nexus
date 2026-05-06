import 'package:flutter/material.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'article_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool isDark;
  const SearchScreen({super.key, required this.isDark});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<Article> _results = [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty || q == _lastQuery) return;
    _lastQuery = q;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await ArticlesService.instance.searchArticles(query: q);
      if (mounted) {
        setState(() {
          _results = result.articles;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Search failed. Try again.';
          _loading = false;
        });
      }
    }
  }

  void _openArticle(Article article) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticleScreen(article: article, isDark: widget.isDark),
      ),
    );
  }

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: TextStyle(color: colors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search articles…',
            hintStyle: TextStyle(color: colors.textSecondary),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: colors.textSecondary),
              onPressed: () {
                _controller.clear();
                setState(() {
                  _results = [];
                  _lastQuery = '';
                  _error = null;
                });
              },
            ),
        ],
      ),
      body: _buildBody(colors),
    );
  }

  Widget _buildBody(DynamicColors colors) {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (_, __) => _SearchSkeleton(colors: colors),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: colors.textSecondary)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _search(_controller.text),
              child: const Text('Retry', style: TextStyle(color: NexusColors.teal)),
            ),
          ],
        ),
      );
    }

    if (_lastQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: colors.muted),
            const SizedBox(height: 16),
            Text(
              'Search for any topic, event, or keyword',
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.article_outlined, size: 64, color: colors.muted),
            const SizedBox(height: 16),
            Text(
              'No results for "$_lastQuery"',
              style: TextStyle(color: colors.textSecondary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _results.length,
      itemBuilder: (_, index) {
        final article = _results[index];
        return _SearchResultCard(
          article: article,
          isDark: widget.isDark,
          colors: colors,
          onTap: () => _openArticle(article),
        );
      },
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final Article article;
  final bool isDark;
  final DynamicColors colors;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.article,
    required this.isDark,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: NexusColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: NexusColors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          article.sourceId,
                          style: TextStyle(fontSize: 12, color: colors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeAgo(article.publishedAt),
                        style: TextStyle(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (article.imageUrl != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  article.imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: colors.muted,
                    child: Icon(Icons.image, color: colors.textSecondary),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _SearchSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(colors, 60, 12),
                const SizedBox(height: 10),
                _bar(colors, double.infinity, 16),
                const SizedBox(height: 6),
                _bar(colors, 200, 16),
                const SizedBox(height: 10),
                _bar(colors, 120, 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(DynamicColors colors, double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
