import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/article_card.dart';
import '../models/article.dart';
import '../services/articles_service.dart';
import '../services/api_client.dart';
import '../services/notification_service.dart';
import '../utils/time_utils.dart';
import 'article_screen.dart';
import 'country_panel.dart';
import 'notifications_screen.dart';

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
  String _selectedSlug = '';
  String _selectedName = '';

  List<Article> _trendingArticles = [];
  List<String> _breakingTitles = [];
  Map<String, int> _regionCounts = {};
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
      if (mounted) setState(() { _trendingArticles = articles; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load articles'; _isLoading = false; });
    }
  }

  Future<void> _loadBreaking() async {
    try {
      final response = await ApiClient.instance.get('/feed/breaking', queryParameters: {'limit': 5});
      final data = response.data['data'] as List<dynamic>;
      if (mounted) {
        setState(() {
          _breakingTitles = data
              .map((e) => (e as Map<String, dynamic>)['title'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadRegions() async {
    try {
      final response = await ApiClient.instance.get('/regions');
      final data = response.data['data'] as List<dynamic>;
      if (mounted) {
        setState(() {
          _regionCounts = {
            for (final e in data)
              (e as Map<String, dynamic>)['slug'] as String:
                  (e['articleCount'] as int? ?? 0),
          };
        });
      }
    } catch (_) {}
  }

  void _onRegionTap(String slug, String name) {
    setState(() {
      _selectedSlug = slug;
      _selectedName = name;
      _showCountryPanel = true;
    });
  }

  Future<void> _showNotificationsPopup(BuildContext context, DynamicColors colors) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => _NotificationsPopup(isDark: widget.isDark, colors: colors),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── App bar ─────────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                backgroundColor: colors.background,
                elevation: 0,
                title: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: NexusColors.teal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text('N',
                            style: TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            )),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Nexus',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        )),
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
                  ValueListenableBuilder<int>(
                    valueListenable: NotificationService.instance.unreadCount,
                    builder: (_, count, __) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_outlined, color: colors.textPrimary),
                          onPressed: () => _showNotificationsPopup(context, colors),
                        ),
                        if (count > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.background, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Breaking news ────────────────────────────────────────────
              if (_breakingTitles.isNotEmpty)
                SliverToBoxAdapter(
                  child: _BreakingNewsBanner(isDark: widget.isDark, titles: _breakingTitles),
                ),

              // ── World map ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Explore Global News',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          )),
                      const SizedBox(height: 4),
                      Text('Tap a region to read its latest stories',
                          style: TextStyle(fontSize: 13, color: colors.textSecondary)),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(
                  height: 300,
                  child: _WorldMap(
                    isDark: widget.isDark,
                    regionCounts: _regionCounts,
                    onRegionTap: _onRegionTap,
                  ),
                ),
              ),

              // ── Trending ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Trending Now',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          )),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildTrendingList(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // ── Country panel overlay ────────────────────────────────────────
          if (_showCountryPanel)
            CountryPanel(
              regionSlug: _selectedSlug,
              regionName: _selectedName,
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
                Text(_error!, style: TextStyle(color: DynamicColors(widget.isDark).textSecondary)),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loadTrending,
                  child: const Text('Try again', style: TextStyle(color: NexusColors.teal)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_trendingArticles.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('No articles yet — check back soon.',
                style: TextStyle(color: DynamicColors(widget.isDark).textSecondary)),
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
              MaterialPageRoute(builder: (_) => ArticleScreen(article: article, isDark: widget.isDark)),
            ),
          );
        },
        childCount: _trendingArticles.length,
      ),
    );
  }
}

// ── World Map ─────────────────────────────────────────────────────────────────

class _RegionConfig {
  final String slug;
  final String name;
  final String emoji;
  final Color color;
  final LatLng center;
  final List<LatLng> polygon;
  // Bounding box for tap detection
  final double minLat, maxLat, minLng, maxLng;

  const _RegionConfig({
    required this.slug,
    required this.name,
    required this.emoji,
    required this.color,
    required this.center,
    required this.polygon,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  bool contains(LatLng p) =>
      p.latitude >= minLat && p.latitude <= maxLat &&
      p.longitude >= minLng && p.longitude <= maxLng;
}

// Detection order: smaller/more specific first to avoid swallowing by larger regions
const _regions = [
  _RegionConfig(
    slug: 'middle-east', name: 'Middle East', emoji: '🕌',
    color: Color(0xFF8B5CF6),
    center: LatLng(27, 44),
    polygon: [LatLng(42, 25), LatLng(42, 63), LatLng(12, 63), LatLng(12, 25)],
    minLat: 12, maxLat: 42, minLng: 25, maxLng: 63,
  ),
  _RegionConfig(
    slug: 'europe', name: 'Europe', emoji: '🏛️',
    color: Color(0xFF3B82F6),
    center: LatLng(52, 10),
    polygon: [LatLng(71, -25), LatLng(71, 40), LatLng(35, 40), LatLng(35, -25)],
    minLat: 35, maxLat: 71, minLng: -25, maxLng: 40,
  ),
  _RegionConfig(
    slug: 'africa', name: 'Africa', emoji: '🌍',
    color: Color(0xFFF59E0B),
    center: LatLng(2, 20),
    polygon: [LatLng(37, -18), LatLng(37, 52), LatLng(-35, 52), LatLng(-35, -18)],
    minLat: -35, maxLat: 37, minLng: -18, maxLng: 52,
  ),
  _RegionConfig(
    slug: 'asia', name: 'Asia', emoji: '🏯',
    color: Color(0xFFEF4444),
    center: LatLng(35, 105),
    polygon: [LatLng(77, 63), LatLng(77, 145), LatLng(-10, 145), LatLng(-10, 63)],
    minLat: -10, maxLat: 77, minLng: 63, maxLng: 145,
  ),
  _RegionConfig(
    slug: 'americas', name: 'Americas', emoji: '🗽',
    color: Color(0xFF10B981),
    center: LatLng(10, -90),
    polygon: [LatLng(73, -170), LatLng(73, -34), LatLng(-56, -34), LatLng(-56, -170)],
    minLat: -56, maxLat: 73, minLng: -170, maxLng: -34,
  ),
  _RegionConfig(
    slug: 'oceania', name: 'Oceania', emoji: '🦘',
    color: Color(0xFF06B6D4),
    center: LatLng(-25, 140),
    polygon: [LatLng(10, 110), LatLng(10, 180), LatLng(-47, 180), LatLng(-47, 110)],
    minLat: -47, maxLat: 10, minLng: 110, maxLng: 180,
  ),
];

class _WorldMap extends StatefulWidget {
  final bool isDark;
  final Map<String, int> regionCounts;
  final void Function(String slug, String name) onRegionTap;

  const _WorldMap({
    required this.isDark,
    required this.regionCounts,
    required this.onRegionTap,
  });

  @override
  State<_WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<_WorldMap> {
  String? _highlighted;

  void _handleTap(LatLng point) {
    for (final region in _regions) {
      if (region.contains(point)) {
        setState(() => _highlighted = region.slug);
        Future.delayed(const Duration(milliseconds: 200),
            () { if (mounted) setState(() => _highlighted = null); });
        widget.onRegionTap(region.slug, region.name);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(20, 10),
              initialZoom: 1.5,
              minZoom: 1.0,
              maxZoom: 5.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
              onTap: (_, latLng) => _handleTap(latLng),
            ),
            children: [
              // Base OSM tile layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.nexus',
                tileBuilder: widget.isDark ? _darkModeTileBuilder : null,
              ),

              // Region polygon overlays
              PolygonLayer(
                polygons: _regions.map((r) {
                  final isHighlighted = _highlighted == r.slug;
                  return Polygon(
                    points: r.polygon,
                    color: r.color.withOpacity(isHighlighted ? 0.45 : 0.22),
                    borderStrokeWidth: isHighlighted ? 2.5 : 1.5,
                    borderColor: r.color.withOpacity(isHighlighted ? 0.9 : 0.6),
                  );
                }).toList(),
              ),

              // Region badge markers
              MarkerLayer(
                markers: _regions.map((r) {
                  final count = widget.regionCounts[r.slug] ?? 0;
                  return Marker(
                    point: r.center,
                    width: 110,
                    height: 58,
                    child: GestureDetector(
                      onTap: () => widget.onRegionTap(r.slug, r.name),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 108),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: r.color,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: r.color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(r.emoji, style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    count > 0 ? '$count' : r.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 108),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dark-mode tile tint
Widget _darkModeTileBuilder(BuildContext context, Widget tile, TileImage image) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix([
      -0.85, 0, 0, 0, 255,
       0, -0.85, 0, 0, 255,
       0, 0, -0.85, 0, 255,
       0, 0,  0, 1, 0,
    ]),
    child: tile,
  );
}

// ── Breaking news banner ──────────────────────────────────────────────────────

class _BreakingNewsBanner extends StatefulWidget {
  final bool isDark;
  final List<String> titles;
  const _BreakingNewsBanner({required this.isDark, required this.titles});

  @override
  State<_BreakingNewsBanner> createState() => _BreakingNewsBannerState();
}

class _BreakingNewsBannerState extends State<_BreakingNewsBanner> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final title = widget.titles[_index];
    return GestureDetector(
      onTap: () => setState(() => _index = (_index + 1) % widget.titles.length),
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
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark ? NexusColors.darkTextPrimary : NexusColors.lightTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (widget.titles.length > 1)
              Icon(Icons.chevron_right,
                  size: 16,
                  color: widget.isDark ? NexusColors.darkTextSecondary : NexusColors.lightTextSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Article skeleton ──────────────────────────────────────────────────────────

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
          _sh(colors, h: 14, w: 80),
          const SizedBox(height: 12),
          _sh(colors, h: 18, w: double.infinity),
          const SizedBox(height: 6),
          _sh(colors, h: 18, w: 200),
          const SizedBox(height: 12),
          _sh(colors, h: 12, w: 120),
        ],
      ),
    );
  }

  Widget _sh(DynamicColors c, {required double h, required double w}) => Container(
        height: h, width: w,
        decoration: BoxDecoration(color: c.muted, borderRadius: BorderRadius.circular(4)));
}

// ── Notifications popup (bell icon) ───────────────────────────────────────────

class _NotificationsPopup extends StatefulWidget {
  final bool isDark;
  final DynamicColors colors;
  const _NotificationsPopup({required this.isDark, required this.colors});

  @override
  State<_NotificationsPopup> createState() => _NotificationsPopupState();
}

class _NotificationsPopupState extends State<_NotificationsPopup> {
  List<AppNotification> _items = [];
  bool _loading = true;

  static const _maxShown = 6;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await NotificationService.instance.fetchPage();
      if (mounted) setState(() { _items = result.items; _loading = false; });
      // Opening the popup counts as having seen the latest notifications.
      NotificationService.instance.markAllRead();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              children: [
                Text('Notifications',
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    )),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NotificationsScreen(isDark: widget.isDark),
                    ));
                  },
                  child: Text('See all',
                      style: TextStyle(color: NexusColors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: NexusColors.teal, strokeWidth: 2)),
              )
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text('No notifications yet.',
                    style: TextStyle(fontSize: 14, color: colors.textSecondary)),
              )
            else
              ..._items.take(_maxShown).map((n) => _PopupTile(item: n, colors: colors)),
          ],
        ),
      ),
    );
  }
}

class _PopupTile extends StatelessWidget {
  final AppNotification item;
  final DynamicColors colors;
  const _PopupTile({required this.item, required this.colors});

  (IconData, Color) get _meta => switch (item.type) {
        'new_comment' => (Icons.chat_bubble_rounded, const Color(0xFF7C83FF)),
        'new_reaction' => (Icons.favorite_rounded, Colors.redAccent),
        'new_post' => (Icons.newspaper_rounded, NexusColors.teal),
        'subscription_activated' => (Icons.workspace_premium_rounded, Colors.amber),
        'subscription_canceled' => (Icons.cancel_outlined, Colors.redAccent),
        'bookmark_added' => (Icons.bookmark_rounded, NexusColors.teal),
        _ => (Icons.notifications_rounded, NexusColors.teal),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = _meta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary)),
                if (item.body != null && item.body!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.body!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ],
                const SizedBox(height: 2),
                Text(timeAgo(item.createdAt), style: TextStyle(fontSize: 11, color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
