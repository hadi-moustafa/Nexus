import 'package:flutter/foundation.dart';
import '../models/article.dart';
import 'api_client.dart';

const _tag = '[ArticlesService]';

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
    debugPrint('$_tag fetchFeed params=$params');

    final response =
        await ApiClient.instance.get('/feed', queryParameters: params);
    debugPrint('$_tag fetchFeed raw keys=${response.data.keys.toList()}');
    final result = _parsePage(response.data);
    debugPrint('$_tag fetchFeed → ${result.articles.length} articles, nextCursor=${result.nextCursor}');
    return result;
  }

  /// Trending articles for the home screen.
  Future<List<Article>> fetchTrending({int limit = 10}) async {
    debugPrint('$_tag fetchTrending limit=$limit');
    final response = await ApiClient.instance
        .get('/trending', queryParameters: {'limit': limit});
    debugPrint('$_tag fetchTrending raw keys=${response.data.keys.toList()}');
    final data = response.data['data'] as List<dynamic>;
    debugPrint('$_tag fetchTrending → ${data.length} articles');
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

  /// Articles for a world-map region (e.g. "europe", "asia", "middle-east").
  Future<({List<Article> articles, String? nextCursor})> fetchArticlesByRegion(
    String regionSlug, {
    int limit = 20,
    String? cursor,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final response = await ApiClient.instance
        .get('/regions/$regionSlug/articles', queryParameters: params);
    return _parsePage(response.data);
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
    debugPrint('$_tag _parsePage body keys=${body.keys.toList()}');
    final rawData = body['data'];
    if (rawData == null) {
      debugPrint('$_tag _parsePage ERROR: "data" key is null — full body: $body');
      return (articles: [], nextCursor: null);
    }
    final data = rawData as List<dynamic>;
    final meta = body['meta'] as Map<String, dynamic>?;
    debugPrint('$_tag _parsePage ${data.length} items, meta=$meta');
    final articles = <Article>[];
    for (var i = 0; i < data.length; i++) {
      try {
        articles.add(Article.fromJson(data[i] as Map<String, dynamic>));
      } catch (e, st) {
        debugPrint('$_tag _parsePage ERROR parsing item $i: $e\n$st\nraw: ${data[i]}');
      }
    }
    return (articles: articles, nextCursor: meta?['nextCursor'] as String?);
  }
}
