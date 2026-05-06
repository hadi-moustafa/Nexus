import '../models/article.dart';
import 'api_client.dart';

class ArticlesService {
  ArticlesService._();
  static final ArticlesService instance = ArticlesService._();

  /// Personalised feed — calls `/feed` which applies user topic preferences
  /// for the "For You" tab. Pass [category] and/or [language] for tab filters.
  ///
  /// Tabs mirror the web:
  ///   For You   → no params
  ///   Lebanon   → category: 'lebanon'
  ///   العربية   → language: 'ar'
  ///   World     → category: 'world'
  ///   Tech      → category: 'technology'
  ///   …etc.
  Future<({List<Article> articles, String? nextCursor})> fetchFeed({
    int limit = 20,
    String? cursor,
    String? category,
    String? language,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (language != null && language.isNotEmpty) params['language'] = language;

    final response =
        await ApiClient.instance.get('/feed', queryParameters: params);
    return _parsePage(response.data);
  }

  /// Trending articles for the home screen.
  Future<List<Article>> fetchTrending({int limit = 10}) async {
    final response = await ApiClient.instance
        .get('/trending', queryParameters: {'limit': limit});
    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => Article.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Direct article list without personalisation (used internally / admin).
  Future<({List<Article> articles, String? nextCursor})> fetchArticles({
    int limit = 20,
    String? cursor,
    String? category,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (category != null) params['category'] = category;
    final response =
        await ApiClient.instance.get('/articles', queryParameters: params);
    return _parsePage(response.data);
  }

  /// Single article by ID.
  Future<Article> fetchArticleById(String id) async {
    final response = await ApiClient.instance.get('/articles/$id');
    return Article.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Full-text search.
  Future<({List<Article> articles, String? nextCursor})> searchArticles({
    required String query,
    int limit = 20,
    String? cursor,
    String? category,
    String? language,
  }) async {
    final params = <String, dynamic>{'q': query, 'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    if (category != null) params['category'] = category;
    if (language != null) params['language'] = language;

    final response =
        await ApiClient.instance.get('/search', queryParameters: params);
    return _parsePage(response.data);
  }

  ({List<Article> articles, String? nextCursor}) _parsePage(
      Map<String, dynamic> body) {
    final data = body['data'] as List<dynamic>;
    final meta = body['meta'] as Map<String, dynamic>?;
    return (
      articles: data
          .map((json) => Article.fromJson(json as Map<String, dynamic>))
          .toList(),
      nextCursor: meta?['nextCursor'] as String?,
    );
  }
}
