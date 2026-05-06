import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../utils/time_utils.dart';
import 'article_screen.dart';
import 'country_panel.dart';

class HomeScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCountryPanel = false;
  String _selectedCountry = '';

  List<Article> _trendingArticles = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final articles = await ArticlesService.instance.fetchTrending(limit: 5);
      setState(() {
        _trendingArticles = articles;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not load articles';
        _isLoading = false;
      });
    }
  }

  void _onCountryTap(String country) {
    setState(() {
      _selectedCountry = country;
      _showCountryPanel = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          // Main Content
          CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: colors.background,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: NexusColors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Nexus',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      widget.isDark ? Icons.light_mode : Icons.dark_mode,
                      color: colors.textPrimary,
                    ),
                    onPressed: widget.onToggleTheme,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: colors.textPrimary,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),

              // Breaking News Banner
              SliverToBoxAdapter(
                child: _BreakingNewsBanner(isDark: widget.isDark),
              ),

              // Interactive Map Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore Global News',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap on a region to discover stories',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Map Placeholder
                      _InteractiveMap(
                        isDark: widget.isDark,
                        onCountryTap: _onCountryTap,
                      ),
                    ],
                  ),
                ),
              ),

              // Trending Stories
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trending Now',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'See all',
                              style: TextStyle(
                                color: NexusColors.teal,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Trending Articles List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildTrendingList(),
              ),

              // Bottom Padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // Country Panel (Bottom Sheet)
          if (_showCountryPanel)
            CountryPanel(
              country: _selectedCountry,
              isDark: widget.isDark,
              onClose: () => setState(() => _showCountryPanel = false),
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingList() {
    if (_isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => _ArticleSkeleton(isDark: widget.isDark),
          childCount: 3,
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Column(
              children: [
                Text(
                  _error!,
                  style: TextStyle(
                    color: DynamicColors(widget.isDark).textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadTrending,
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

    if (_trendingArticles.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'No articles yet — check back soon.',
              style: TextStyle(
                color: DynamicColors(widget.isDark).textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final article = _trendingArticles[index];
          return ArticleCard(
            title: article.title,
            source: article.displaySource,
            timeAgo: timeAgo(article.publishedAt),
            category: article.category,
            isDark: widget.isDark,
            imageUrl: article.imageUrl,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ArticleScreen(article: article, isDark: widget.isDark),
              ),
            ),
          );
        },
        childCount: _trendingArticles.length,
      ),
    );
  }
}

class _BreakingNewsBanner extends StatelessWidget {
  final bool isDark;

  const _BreakingNewsBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Breaking: Major diplomatic talks underway in Geneva',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark 
                    ? NexusColors.darkTextPrimary 
                    : NexusColors.lightTextPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveMap extends StatelessWidget {
  final bool isDark;
  final Function(String) onCountryTap;

  const _InteractiveMap({
    required this.isDark,
    required this.onCountryTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          // Map Background
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF1E1F24),
                          const Color(0xFF141519),
                        ]
                      : [
                          const Color(0xFFE8E6E1),
                          const Color(0xFFF7F5F0),
                        ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.public,
                  size: 120,
                  color: NexusColors.teal.withOpacity(0.2),
                ),
              ),
            ),
          ),
          // Hotspot Markers
          _MapHotspot(
            left: 60,
            top: 70,
            label: 'Europe',
            count: 24,
            isDark: isDark,
            onTap: () => onCountryTap('Europe'),
          ),
          _MapHotspot(
            left: 200,
            top: 90,
            label: 'Asia',
            count: 18,
            isDark: isDark,
            onTap: () => onCountryTap('Asia'),
          ),
          _MapHotspot(
            left: 100,
            top: 140,
            label: 'Africa',
            count: 12,
            isDark: isDark,
            onTap: () => onCountryTap('Africa'),
          ),
          _MapHotspot(
            left: 280,
            top: 60,
            label: 'Americas',
            count: 31,
            isDark: isDark,
            onTap: () => onCountryTap('Americas'),
          ),
        ],
      ),
    );
  }
}

class _MapHotspot extends StatelessWidget {
  final double left;
  final double top;
  final String label;
  final int count;
  final bool isDark;
  final VoidCallback onTap;

  const _MapHotspot({
    required this.left,
    required this.top,
    required this.label,
    required this.count,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: NexusColors.teal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: NexusColors.teal.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? NexusColors.darkTextPrimary
                    : NexusColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton placeholder shown while trending articles are loading.
class _ArticleSkeleton extends StatelessWidget {
  final bool isDark;
  const _ArticleSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);
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
          _shimmer(colors, height: 14, width: 80),
          const SizedBox(height: 12),
          _shimmer(colors, height: 18, width: double.infinity),
          const SizedBox(height: 6),
          _shimmer(colors, height: 18, width: 200),
          const SizedBox(height: 12),
          _shimmer(colors, height: 12, width: 120),
        ],
      ),
    );
  }

  Widget _shimmer(DynamicColors colors, {required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
