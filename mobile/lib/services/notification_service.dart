import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'api_client.dart';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final String? postId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.postId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: j['type'] as String,
        title: j['title'] as String,
        body: j['body'] as String?,
        postId: j['post_id'] as String?,
        isRead: j['read_at'] != null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  RealtimeChannel? _channel;
  final unreadCount = ValueNotifier<int>(0);

  void subscribe(String userId) {
    _channel = Supabase.instance.client
        .channel('notifs:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            unreadCount.value = unreadCount.value + 1;
          },
        )
        .subscribe();

    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final res = await ApiClient.instance.get('/user/notifications');
      final meta = res.data['meta'] as Map<String, dynamic>?;
      unreadCount.value = (meta?['unreadCount'] as num?)?.toInt() ?? 0;
    } catch (_) {}
  }

  Future<({List<AppNotification> items, String? nextCursor})> fetchPage({
    String? cursor,
  }) async {
    final params = <String, dynamic>{};
    if (cursor != null) params['cursor'] = cursor;
    final res = await ApiClient.instance.get('/user/notifications', queryParameters: params);
    final data = res.data['data'] as List<dynamic>;
    final meta = res.data['meta'] as Map<String, dynamic>?;
    return (
      items: data.map((j) => AppNotification.fromJson(j as Map<String, dynamic>)).toList(),
      nextCursor: meta?['nextCursor'] as String?,
    );
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.instance.post('/user/notifications/read');
      unreadCount.value = 0;
    } catch (_) {}
  }

  void unsubscribe() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }
    unreadCount.value = 0;
  }
}
