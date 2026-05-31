import '../models/journalist_post.dart';
import '../models/journalist_request.dart';
import 'api_client.dart';

class JournalistService {
  JournalistService._();
  static final JournalistService instance = JournalistService._();

  /// Fetch public feed of journalist posts.
  Future<({List<JournalistPost> posts, String? nextCursor})> fetchPosts({
    int limit = 20,
    String? cursor,
    String? journalistId,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (journalistId != null) params['journalist_id'] = journalistId;

    final res = await ApiClient.instance.get('/journalist/posts', queryParameters: params);
    final data = res.data['data'] as List<dynamic>;
    final meta = res.data['meta'] as Map<String, dynamic>?;
    return (
      posts: data.map((p) => JournalistPost.fromJson(p as Map<String, dynamic>)).toList(),
      nextCursor: meta?['nextCursor'] as String?,
    );
  }

  /// Fetch a single post by id.
  Future<JournalistPost> fetchPost(String id) async {
    final res = await ApiClient.instance.get('/journalist/posts/$id');
    return JournalistPost.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Fetch comments for a post.
  Future<({List<PostComment> comments, String? nextCursor})> fetchComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;

    final res = await ApiClient.instance.get(
      '/journalist/posts/$postId/comments',
      queryParameters: params,
    );
    final data = res.data['data'] as List<dynamic>;
    final meta = res.data['meta'] as Map<String, dynamic>?;
    return (
      comments: data.map((c) => PostComment.fromJson(c as Map<String, dynamic>)).toList(),
      nextCursor: meta?['nextCursor'] as String?,
    );
  }

  /// Post a comment on a journalist post.
  Future<PostComment> addComment(String postId, String body) async {
    final res = await ApiClient.instance.post(
      '/journalist/posts/$postId/comments',
      data: {'body': body},
    );
    return PostComment.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Delete a comment.
  Future<void> deleteComment(String postId, String commentId) async {
    await ApiClient.instance.delete('/journalist/posts/$postId/comments/$commentId');
  }

  /// Get reaction counts + my reaction for a post.
  Future<({Map<String, int> counts, String? myReaction})> fetchReactions(String postId) async {
    final res = await ApiClient.instance.get('/journalist/posts/$postId/reactions');
    final data = res.data['data'] as Map<String, dynamic>;
    final raw = data['counts'] as Map<String, dynamic>? ?? {};
    return (
      counts: raw.map((k, v) => MapEntry(k, (v as num).toInt())),
      myReaction: data['myReaction'] as String?,
    );
  }

  /// Toggle a reaction on a post.
  Future<String> toggleReaction(String postId, String type) async {
    final res = await ApiClient.instance.post(
      '/journalist/posts/$postId/reactions',
      data: {'type': type},
    );
    return res.data['data']['action'] as String;
  }

  /// Fetch the journalist's own profile + recent posts (journalist only).
  Future<JournalistProfile> fetchMyProfile() async {
    final res = await ApiClient.instance.get('/journalist/profile');
    return JournalistProfile.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Create a new post (journalist only).
  Future<JournalistPost> createPost({
    required String title,
    required String body,
    String? imageUrl,
    String category = 'general',
  }) async {
    final res = await ApiClient.instance.post(
      '/journalist/posts',
      data: {
        'title': title,
        'body': body,
        if (imageUrl != null) 'image_url': imageUrl,
        'category': category,
      },
    );
    return JournalistPost.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Edit own post.
  Future<void> editPost(String postId, {String? title, String? body, String? imageUrl, String? category}) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (body != null) data['body'] = body;
    if (imageUrl != null) data['image_url'] = imageUrl;
    if (category != null) data['category'] = category;
    await ApiClient.instance.patch('/journalist/posts/$postId', data: data);
  }

  /// Delete own post.
  Future<void> deletePost(String postId) async {
    await ApiClient.instance.delete('/journalist/posts/$postId');
  }

  // ── Post bookmarks ────────────────────────────────────────────────────────

  /// Returns true if the current user has bookmarked [postId].
  Future<bool> checkPostBookmark(String postId) async {
    final res = await ApiClient.instance.get('/journalist/posts/$postId/bookmark');
    return res.data['data']['isBookmarked'] as bool;
  }

  /// Toggles bookmark for [postId]. Returns the new bookmark state (true = bookmarked).
  Future<bool> togglePostBookmark(String postId) async {
    final res = await ApiClient.instance.post('/journalist/posts/$postId/bookmark');
    return res.data['data']['isBookmarked'] as bool;
  }

  // ── Journalist request flow ───────────────────────────────────────────────

  /// Fetch current user's journalist request (null if no request yet).
  Future<JournalistRequest?> fetchMyRequest() async {
    final res = await ApiClient.instance.get('/user/journalist-request');
    final data = res.data['data'];
    if (data == null) return null;
    return JournalistRequest.fromJson(data as Map<String, dynamic>);
  }

  /// Submit or re-submit a journalist request.
  Future<JournalistRequest> submitRequest({String? message}) async {
    final res = await ApiClient.instance.post(
      '/user/journalist-request',
      data: {if (message != null && message.isNotEmpty) 'message': message},
    );
    return JournalistRequest.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
