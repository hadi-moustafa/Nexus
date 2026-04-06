import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../widgets/category_chip.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../utils/time_utils.dart';

class FeedScreen extends StatefulWidget {
  final bool isDark;

  const FeedScreen({super.key, required this.isDark});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String _selectedCategory = 'For You';

  final List<String> _categories = [
    'For You',
    'World',
    'Technology',
    'Business',
    'Science',
    'Health',
    'Sports',
  ];

  List<Article> _articles = [];
  bool _isLoading = false;
  String? _error;

  // Maps UI category labels to API category param values.
  // 'For You' → no filter (null). Others are lowercased.
  String? get _apiCategory {
    if (_selectedCategory == 'For You') return null;
    return _selectedCategory.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ArticlesService.instance.fetchArticles(
        limit: 20,
        category: _apiCategory,
      );
      setState(() {
        _articles = result.articles;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not load articles';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
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
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.tune, color: colors.textPrimary),
                onPressed: () {},
              ),
            ],
          ),

          // Category Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CategoryChipList(
                categories: _categories,
                selectedCategory: _selectedCategory,
                isDark: widget.isDark,
                onCategorySelected: (category) {
                  setState(() => _selectedCategory = category);
                  _loadArticles();
                },
              ),
            ),
          ),

          // Lebanese Spotlight Section
          SliverToBoxAdapter(
            child: _SpotlightSection(isDark: widget.isDark),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Stories',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.muted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Just now',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Articles List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _buildArticleList(colors),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleList(DynamicColors colors) {
    if (_isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => _FeedSkeleton(colors: colors),
          childCount: 5,
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              children: [
                Text(_error!, style: TextStyle(color: colors.textSecondary)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadArticles,
                  child: const Text(
                    'Try again',
                    style: TextStyle(color: NexusColors.teal),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
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
            source: article.sourceId,
            timeAgo: timeAgo(article.publishedAt),
            category: article.category,
            isDark: widget.isDark,
            imageUrl: article.imageUrl,
          );
        },
        childCount: _articles.length,
      ),
    );
  }
}

class _SpotlightSection extends StatelessWidget {
  final bool isDark;

  const _SpotlightSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NexusColors.amber.withOpacity(0.15),
            NexusColors.teal.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NexusColors.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: NexusColors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Lebanese Spotlight',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? NexusColors.darkBg : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Beirut Tech Week Showcases Regional Innovation',
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Annual technology conference brings together startups, investors, and industry leaders from across the MENA region.',
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'L\'Orient Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
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
                '30 min ago',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder shown while feed articles are loading.
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
