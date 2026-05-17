import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  final bool isDark;

  const LeaderboardScreen({super.key, required this.isDark});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _entries = [];
  Map<String, dynamic>? _myRank;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _offset = 0;
  static const int _pageSize = 50;
  bool _hasMore = true;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });
    try {
      final result = await UserService.instance
          .fetchLeaderboard(limit: _pageSize, offset: 0);
      setState(() {
        _entries = result.entries;
        _myRank = result.myRank;
        _loading = false;
        _hasMore = result.entries.length == _pageSize;
        _offset = result.entries.length;
      });
    } catch (_) {
      setState(() {
        _error = 'Could not load leaderboard';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await UserService.instance
          .fetchLeaderboard(limit: _pageSize, offset: _offset);
      setState(() {
        _entries.addAll(result.entries);
        _hasMore = result.entries.length == _pageSize;
        _offset += result.entries.length;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = DynamicColors(widget.isDark);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Leaderboard',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: NexusColors.teal))
          : _error != null
              ? _buildError(colors)
              : RefreshIndicator(
                  color: NexusColors.teal,
                  onRefresh: _load,
                  child: CustomScrollView(
                    controller: _scroll,
                    slivers: [
                      if (_myRank != null) ...[
                        SliverToBoxAdapter(child: _buildMyRankBanner(colors)),
                      ],
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            if (i < _entries.length) {
                              return _buildEntry(_entries[i], colors);
                            }
                            return _loadingMore
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                        child: CircularProgressIndicator(
                                            color: NexusColors.teal)),
                                  )
                                : const SizedBox.shrink();
                          },
                          childCount: _entries.length + 1,
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(DynamicColors colors) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: TextStyle(color: colors.textSecondary, fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: NexusColors.teal),
              onPressed: _load,
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Widget _buildMyRankBanner(DynamicColors colors) {
    final rank = _myRank!['rank'] as int? ?? 0;
    final xp = _myRank!['totalXp'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NexusColors.teal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NexusColors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: NexusColors.teal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your rank: #$rank · $xp XP',
              style: const TextStyle(
                color: NexusColors.teal,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(LeaderboardEntry entry, DynamicColors colors) {
    final isTop3 = entry.rank <= 3;
    final medalColors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade300];
    final medal = isTop3 ? ['🥇', '🥈', '🥉'][entry.rank - 1] : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isTop3
            ? NexusColors.teal.withOpacity(0.06)
            : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? medalColors[entry.rank - 1].withOpacity(0.3)
              : colors.border,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center)
                : Text(
                    '#${entry.rank}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: NexusColors.teal.withOpacity(0.15),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: NexusColors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.totalXp} XP',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isTop3 ? medalColors[entry.rank - 1] : colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
