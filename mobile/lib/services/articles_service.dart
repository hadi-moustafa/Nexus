import '../models/article.dart';
import 'api_client.dart';

/// Wraps all article-related API calls to /api/v1/trending and /api/v1/articles.
///
/// Never returns raw Maps — always typed Article objects.
/// Never interacts with UI — throws exceptions on failure for callers to handle.
class ArticlesService {
  ArticlesService._();
  static final ArticlesService instance = ArticlesService._();

  /// Fetches the latest trending articles.
  Future<List<Article>> fetchTrending({int limit = 10}) async {
    final response = await ApiClient.instance.get(
      '/trending',
      queryParameters: {'limit': limit},
    );
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a paginated article list, optionally filtered by [category].
  ///
  /// Pass [cursor] from a previous response's [nextCursor] to load more.
  /// [category] must match the API category values (e.g. 'technology', 'world').
  /// Pass null or omit [category] for all categories.
  Future<({List<Article> articles, String? nextCursor})> fetchArticles({
    int limit = 20,
    String? cursor,
    String? category,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (category != null) params['category'] = category;

    final response = await ApiClient.instance
        .get('/articles', queryParameters: params);

    final data = response.data['data'] as List<dynamic>;
    final meta = response.data['meta'] as Map<String, dynamic>?;

    return (
      articles: data
          .map((json) => Article.fromJson(json as Map<String, dynamic>))
          .toList(),
      nextCursor: meta?['nextCursor'] as String?,
    );
  }

  /// Fetches a single article by ID.
  Future<Article> fetchArticleById(String id) async {
    final response = await ApiClient.instance.get('/articles/$id');
    return Article.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
