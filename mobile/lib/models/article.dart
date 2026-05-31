/// Dart model for the Article type.
/// Mirrors web/src/types/index.ts → Article exactly.
class Article {
  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String sourceId;
  final String sourceName;
  final String category;
  final String language;
  final String? countryCode;
  final int viewCount;
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
    this.sourceName = '',
    required this.category,
    required this.language,
    this.countryCode,
    this.viewCount = 0,
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
      sourceId: json['sourceId'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      category: json['category'] as String,
      language: json['language'] as String,
      countryCode: json['countryCode'] as String?,
      viewCount: json['viewCount'] as int? ?? 0,
      region: json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'content': content,
        'url': url,
        'imageUrl': imageUrl,
        'publishedAt': publishedAt.toIso8601String(),
        'sourceId': sourceId,
        'sourceName': sourceName,
        'category': category,
        'language': language,
        'countryCode': countryCode,
        'viewCount': viewCount,
        'region': region,
      };

  /// Display name for the source — falls back to sourceId if name is empty.
  String get displaySource => sourceName.isNotEmpty ? sourceName : sourceId;
}
