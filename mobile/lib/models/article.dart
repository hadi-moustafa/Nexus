/// Dart model for the Article type.
/// Mirrors web/src/types/index.ts → Article exactly.
/// Field names match the camelCase keys in the /api/v1 JSON responses.
class Article {
  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String sourceId;
  final String category;
  final String language;
  final String? region;

  const Article({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    required this.sourceId,
    required this.category,
    required this.language,
    this.region,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String?,
      content: json['content'] as String?,
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      sourceId: json['sourceId'] as String,
      category: json['category'] as String,
      language: json['language'] as String,
      region: json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'content': content,
      'url': url,
      'imageUrl': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'sourceId': sourceId,
      'category': category,
      'language': language,
      'region': region,
    };
  }
}
