import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../utils/time_utils.dart';
import 'article_screen.dart';
import 'premium_screen.dart';
import 'search_screen.dart';

// Mirrors the tab definitions in the web feed page.
typedef _Tab = ({String label, String category, String language});

const List<_Tab> _kTabs = [
  (label: 'For You',       category: '',             language: ''),
  (label: 'Lebanon',       category: 'lebanon',      language: ''),
  (label: 'العربية',       category: '',             language: 'ar'),
  (label: 'World',         category: 'world',        language: ''),
  (label: 'Tech',          category: 'technology',   language: ''),
  (label: 'Business',      category: 'business',     language: ''),
  (label: 'Sports',        category: 'sports',       language: ''),
  (label: 'Science',       category: 'science',      language: ''),
  (label: 'Health',        category: 'health',       language: ''),
  (label: 'Entertainment', category: 'entertainment',language: ''),
];

class FeedScreen extends StatefulWidget {
  final bool isDark;
  const FeedScreen({super.key, required this.isDark});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  _Tab _activeTab = _kTabs[0];
  List<Article> _articles = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _cursor;
  String? _error;
  bool _premiumLocked = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      _load(reset: false);
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _premiumLocked = false;
        _articles = [];
        _cursor = null;
        _hasMore = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final tab = _activeTab;
      debugPrint('[FeedScreen] loading tab="${tab.label}" category="${tab.category}" lang="${tab.language}" reset=$reset cursor=$_cursor');
      final result = await ArticlesService.instance.fetchFeed(
        limit: 20,
        cursor: reset ? null : _cursor,
        category: tab.category.isEmpty ? null : tab.category,
        language: tab.language.isEmpty ? null : tab.language,
      );
      debugPrint('[FeedScreen] loaded ${result.articles.length} articles, nextCursor=${result.nextCursor}');

      if (!mounted) return;
      setState(() {
        if (reset) {
          _articles = result.articles;
        } else {
          _articles = [..._articles, ...result.articles];
        }
        _cursor = result.nextCursor;
        _hasMore = result.nextCursor != null;
        _loading = false;
        _loadingMore = false;
      });
    } on DioException catch (e, st) {
      debugPrint('[FeedScreen] _load ERROR: $e\n$st');
      if (!mounted) return;
      if (e.response?.statusCode == 403) {
        setState(() {
          _premiumLocked = true;
          _loading = false;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _error = 'Could not load articles';
          _loading = false;
          _loadingMore = false;
        });
      }
    } catch (e, st) {
      debugPrint('[FeedScreen] _load ERROR: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = 'Could not load articles';
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _selectTab(_Tab tab) {
    if (tab.label == _activeTab.label) return;
    setState(() => _activeTab = tab);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        color: NexusColors.teal,
        onRefresh: () => _load(reset: true),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App bar
            SliverAppBar(
              floating: true,
              backgroundColor: colors.background,
              elevation: 0,
              title: Text(
                'Your Feed',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: colors.textPrimary),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SearchScreen(isDark: widget.isDark),
                    ),
                  ),
                ),
              ],
            ),

            // Category tabs
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsDelegate(
                tabs: _kTabs,
                activeLabel: _activeTab.label,
                isDark: widget.isDark,
                onSelected: _selectTab,
              ),
            ),

            // Articles
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: _buildContent(colors),
            ),

            // Load-more indicator
            if (_loadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: NexusColors.teal,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(DynamicColors colors) {
    if (_loading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => _FeedSkeleton(colors: colors),
          childCount: 5,
        ),
      );
    }

    if (_premiumLocked) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: NexusColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: NexusColors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.lock_rounded,
                        size: 48, color: NexusColors.amber),
                    const SizedBox(height: 16),
                    Text(
                      'Premium Content',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The Arabic feed is available exclusively for Premium subscribers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context)
                            .push(MaterialPageRoute(
                              builder: (_) =>
                                  PremiumScreen(isDark: widget.isDark),
                            ))
                            .then((_) => _load(reset: true)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexusColors.amber,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Upgrade to Premium',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(_error!, style: TextStyle(color: colors.textSecondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _load(reset: true),
                child: const Text('Try again',
                    style: TextStyle(color: NexusColors.teal)),
              ),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'No articles in this category yet.',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final article = _articles[index];
          return ArticleCard(
            title: article.title,
            source: article.displaySource,
            timeAgo: timeAgo(article.publishedAt),
            category: article.category,
            imageUrl: article.imageUrl,
            isDark: widget.isDark,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ArticleScreen(article: article, isDark: widget.isDark),
              ),
            ),
          );
        },
        childCount: _articles.length,
      ),
    );
  }
}

// ── Sticky tabs header ─────────────────────────────────────────────────────────

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  final List<_Tab> tabs;
  final String activeLabel;
  final bool isDark;
  final void Function(_Tab) onSelected;

  const _TabsDelegate({
    required this.tabs,
    required this.activeLabel,
    required this.isDark,
    required this.onSelected,
  });

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = DynamicColors(isDark);
    return Container(
      color: colors.background,
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = tabs[i];
          final active = tab.label == activeLabel;
          return GestureDetector(
            onTap: () => onSelected(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color:
                    active ? NexusColors.teal : colors.muted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tab.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                  color:
                      active ? Colors.white : colors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(_TabsDelegate old) =>
      old.activeLabel != activeLabel || old.isDark != isDark;
}

// ── Skeleton ───────────────────────────────────────────────────────────────────

class _FeedSkeleton extends StatelessWidget {
  final DynamicColors colors;
  const _FeedSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _bar(80, 12),
          const SizedBox(height: 10),
          _bar(double.infinity, 18),
          const SizedBox(height: 6),
          _bar(220, 18),
          const SizedBox(height: 12),
          _bar(140, 12),
        ],
      ),
    );
  }

  Widget _bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
