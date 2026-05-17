import '../models/user_stats.dart';
import 'api_client.dart';

class LeaderboardEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int totalXp;
  final int rank;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.totalXp,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        userId: json['userId'] as String,
        displayName: json['displayName'] as String? ?? 'Anonymous',
        avatarUrl: json['avatarUrl'] as String?,
        totalXp: json['totalXp'] as int? ?? 0,
        rank: json['rank'] as int? ?? 0,
      );
}

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  Future<UserStats> fetchStats() async {
    final response = await ApiClient.instance.get('/user/stats');
    return UserStats.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<({List<BookmarkedArticle> bookmarks, String? nextCursor})>
      fetchBookmarks({int limit = 20, String? cursor}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final response = await ApiClient.instance
        .get('/user/bookmarks', queryParameters: params);
    final data = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>?;

    return (
      bookmarks: data
          .map((b) =>
              BookmarkedArticle.fromJson(b as Map<String, dynamic>))
          .toList(),
      nextCursor: meta?['nextCursor'] as String?,
    );
  }

  /// Adds an article to bookmarks.
  /// Throws on error. Returns the bookmark id.
  Future<String> addBookmark(String articleId) async {
    final response = await ApiClient.instance.post(
      '/user/bookmarks',
      data: {'articleId': articleId},
    );
    return response.data['data']['id'] as String;
  }

  /// Removes an article from bookmarks.
  Future<void> removeBookmark(String articleId) async {
    await ApiClient.instance.delete(
      '/user/bookmarks',
      queryParameters: {'articleId': articleId},
    );
  }

  Future<({List<LeaderboardEntry> entries, Map<String, dynamic>? myRank})>
      fetchLeaderboard({int limit = 50, int offset = 0}) async {
    final response = await ApiClient.instance.get(
      '/leaderboard',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>?;
    return (
      entries: data
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      myRank: meta?['myRank'] as Map<String, dynamic>?,
    );
  }

  Future<void> updateDisplayName(String displayName) async {
    await ApiClient.instance.patch(
      '/user/profile',
      data: {'displayName': displayName},
    );
  }
}
