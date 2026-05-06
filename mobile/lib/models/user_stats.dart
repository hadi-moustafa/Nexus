import 'article.dart';

class UserStats {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int quizzesCompleted;
  final int perfectScores;
  final int articlesRead;

  const UserStats({
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.quizzesCompleted,
    required this.perfectScores,
    required this.articlesRead,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalXp: json['totalXp'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      quizzesCompleted: json['quizzesCompleted'] as int? ?? 0,
      perfectScores: json['perfectScores'] as int? ?? 0,
      articlesRead: json['articlesRead'] as int? ?? 0,
    );
  }

  static UserStats get empty => const UserStats(
        totalXp: 0,
        currentStreak: 0,
        longestStreak: 0,
        quizzesCompleted: 0,
        perfectScores: 0,
        articlesRead: 0,
      );
}

class BookmarkedArticle {
  final String bookmarkId;
  final String articleId;
  final String createdAt;
  // Full article object — available when the bookmark API includes article data.
  final Article? article;

  const BookmarkedArticle({
    required this.bookmarkId,
    required this.articleId,
    required this.createdAt,
    this.article,
  });

  factory BookmarkedArticle.fromJson(Map<String, dynamic> json) {
    final articleJson = json['article'] as Map<String, dynamic>?;
    return BookmarkedArticle(
      bookmarkId: json['id'] as String,
      articleId: json['articleId'] as String,
      createdAt: json['createdAt'] as String,
      article: articleJson != null ? Article.fromJson(articleJson) : null,
    );
  }

  // Convenience getters delegating to the nested article.
  String get title => article?.title ?? '';
  String? get imageUrl => article?.imageUrl;
  String get displaySource => article?.displaySource ?? '';
  String get category => article?.category ?? '';
  DateTime get publishedAt => article?.publishedAt ?? DateTime.now();
}
