import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/owl_mascot.dart';

class NotificationsScreen extends StatefulWidget {
  final bool isDark;
  const NotificationsScreen({super.key, required this.isDark});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  String? _nextCursor;
  bool _loading = true;
  bool _loadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
    NotificationService.instance.markAllRead();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _nextCursor != null &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await NotificationService.instance.fetchPage();
      if (mounted) {
        setState(() {
          _items = result.items;
          _nextCursor = result.nextCursor;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_nextCursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final result = await NotificationService.instance.fetchPage(cursor: _nextCursor);
      if (mounted) {
        setState(() {
          _items.addAll(result.items);
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
              onPressed: () {
                NotificationService.instance.markAllRead();
                setState(() {
                  _items = _items.map((n) => AppNotification(
                    id: n.id,
                    type: n.type,
                    title: n.title,
                    body: n.body,
                    postId: n.postId,
                    isRead: true,
                    createdAt: n.createdAt,
                  )).toList();
                });
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: NexusColors.teal,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? _buildSkeletons(colors)
          : _items.isEmpty
              ? _buildEmpty(colors)
              : RefreshIndicator(
                  color: NexusColors.teal,
                  onRefresh: _load,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
                    itemCount: _items.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: NexusColors.teal, strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return _NotificationTile(
                        item: _items[i],
                        colors: colors,
                        isDark: widget.isDark,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildSkeletons(DynamicColors colors) => ListView(
        children: List.generate(
          6,
          (_) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: colors.muted, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          height: 12,
                          decoration: BoxDecoration(
                              color: colors.muted,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 6),
                      Container(
                          height: 10,
                          width: 160,
                          decoration: BoxDecoration(
                              color: colors.muted,
                              borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildEmpty(DynamicColors colors) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OwlMascot(size: 88, mood: OwlMood.neutral),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No notifications yet.',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
          ],
        ),
      );
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification item;
  final DynamicColors colors;
  final bool isDark;

  const _NotificationTile({
    required this.item,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = _meta(item.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: item.isRead
            ? colors.surface
            : (isDark
                ? NexusColors.teal.withOpacity(0.07)
                : NexusColors.teal.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.isRead
              ? colors.border
              : NexusColors.teal.withOpacity(0.25),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: item.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                          color: colors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      if (item.body != null && item.body!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.body!,
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        timeAgo(item.createdAt),
                        style: TextStyle(
                            fontSize: 11, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: NexusColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (IconData, Color) _meta(String type) => switch (type) {
        'new_comment' => (Icons.chat_bubble_rounded, const Color(0xFF7C83FF)),
        'new_reaction' => (Icons.favorite_rounded, Colors.redAccent),
        'new_post' => (Icons.newspaper_rounded, NexusColors.teal),
        _ => (Icons.notifications_rounded, NexusColors.teal),
      };
}
