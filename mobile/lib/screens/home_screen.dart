import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../services/api_client.dart';
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

class _RegionData {
  final String slug;
  final String name;
  final int articleCount;
  _RegionData({required this.slug, required this.name, required this.articleCount});
  factory _RegionData.fromJson(Map<String, dynamic> j) => _RegionData(
        slug: j['slug'] as String,
        name: j['name'] as String,
        articleCount: j['articleCount'] as int? ?? 0,
      );
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCountryPanel = false;
  String _selectedCountry = '';

  List<Article> _trendingArticles = [];
  List<String> _breakingTitles = [];
  List<_RegionData> _regions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadTrending();
    _loadBreaking();
    _loadRegions();
  }

  Future<void> _loadTrending() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final articles = await ArticlesService.instance.fetchTrending(limit: 5);
      debugPrint('[HomeScreen] trending loaded: ${articles.length} articles');
      if (mounted) setState(() { _trendingArticles = articles; _isLoading = false; });
    } catch (e, st) {
      debugPrint('[HomeScreen] _loadTrending ERROR: $e\n$st');
      if (mounted) setState(() { _error = 'Could not load articles'; _isLoading = false; });
    }
  }

  Future<void> _loadBreaking() async {
    try {
      debugPrint('[HomeScreen] loading breaking news');
      final response = await ApiClient.instance.get('/feed/breaking', queryParameters: {'limit': 5});
      debugPrint('[HomeScreen] breaking raw keys=${response.data.keys.toList()}');
      final data = response.data['data'] as List<dynamic>;
      debugPrint('[HomeScreen] breaking ${data.length} items');
      if (mounted) {
        setState(() {
          _breakingTitles = data
              .map((e) => (e as Map<String, dynamic>)['title'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
        });
      }
    } catch (e, st) {
      debugPrint('[HomeScreen] _loadBreaking ERROR: $e\n$st');
    }
  }

  Future<void> _loadRegions() async {
    try {
      debugPrint('[HomeScreen] loading regions');
      final response = await ApiClient.instance.get('/regions');
      debugPrint('[HomeScreen] regions raw keys=${response.data.keys.toList()}');
      final data = response.data['data'] as List<dynamic>;
      debugPrint('[HomeScreen] regions ${data.length} items');
      if (mounted) {
        setState(() {
          _regions = data
              .map((e) => _RegionData.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e, st) {
      debugPrint('[HomeScreen] _loadRegions ERROR: $e\n$st');
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
              if (_breakingTitles.isNotEmpty)
                SliverToBoxAdapter(
                  child: _BreakingNewsBanner(
                    isDark: widget.isDark,
                    titles: _breakingTitles,
                  ),
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
                        regions: _regions,
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

class _BreakingNewsBanner extends StatefulWidget {
  final bool isDark;
  final List<String> titles;

  const _BreakingNewsBanner({required this.isDark, required this.titles});

  @override
  State<_BreakingNewsBanner> createState() => _BreakingNewsBannerState();
}

class _BreakingNewsBannerState extends State<_BreakingNewsBanner> {
  int _index = 0;

  void _next() {
    if (widget.titles.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.titles.length);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.titles.isNotEmpty ? widget.titles[_index] : '';
    return GestureDetector(
      onTap: _next,
      child: Container(
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
                  Text('LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? NexusColors.darkTextPrimary
                      : NexusColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.titles.length > 1)
              Icon(Icons.chevron_right,
                  size: 16,
                  color: widget.isDark
                      ? NexusColors.darkTextSecondary
                      : NexusColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }
}

// Pixel positions on the 360-wide map container for each region slug
const _regionPositions = {
  'europe':      {'left': 60.0,  'top': 70.0},
  'asia':        {'left': 200.0, 'top': 90.0},
  'africa':      {'left': 100.0, 'top': 140.0},
  'americas':    {'left': 280.0, 'top': 60.0},
  'middle-east': {'left': 155.0, 'top': 115.0},
  'oceania':     {'left': 255.0, 'top': 155.0},
};

class _InteractiveMap extends StatelessWidget {
  final bool isDark;
  final Function(String) onCountryTap;
  final List<_RegionData> regions;

  const _InteractiveMap({
    required this.isDark,
    required this.onCountryTap,
    required this.regions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(isDark);

    // Build a lookup map slug → count from loaded regions
    final countBySlug = {for (final r in regions) r.slug: r.articleCount};

    // Default positions for the hotspots
    final hotspots = _regionPositions.entries
        .where((e) => (countBySlug[e.key] ?? 0) > 0 || regions.isEmpty)
        .map((e) {
      final regionName = regions.firstWhere(
        (r) => r.slug == e.key,
        orElse: () => _RegionData(
          slug: e.key,
          name: e.key[0].toUpperCase() + e.key.substring(1),
          articleCount: 0,
        ),
      );
      return (
        slug: e.key,
        name: regionName.name,
        count: countBySlug[e.key] ?? 0,
        left: e.value['left']!,
        top: e.value['top']!,
      );
    }).toList();

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E1F24), const Color(0xFF141519)]
                      : [const Color(0xFFE8E6E1), const Color(0xFFF7F5F0)],
                ),
              ),
              child: Center(
                child: Icon(Icons.public, size: 120,
                    color: NexusColors.teal.withOpacity(0.2)),
              ),
            ),
          ),
          // Show hotspots only for regions with articles (or all if no data loaded yet)
          for (final h in hotspots)
            _MapHotspot(
              left: h.left,
              top: h.top,
              label: h.name,
              count: h.count,
              isDark: isDark,
              onTap: () => onCountryTap(h.name),
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
