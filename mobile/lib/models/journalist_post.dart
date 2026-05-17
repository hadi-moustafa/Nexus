/// Dart model mirroring web/src/types/index.ts → JournalistPost and PostComment.

class JournalistPost {
  final String id;
  final String journalistId;
  final String journalistName;
  final String? journalistAvatarUrl;
  final bool isVerified;
  final String title;
  final String body;
  final String? imageUrl;
  final String category;
  final int viewCount;
  final int commentCount;
  final int reactionCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalistPost({
    required this.id,
    required this.journalistId,
    required this.journalistName,
    this.journalistAvatarUrl,
    required this.isVerified,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.category,
    required this.viewCount,
    required this.commentCount,
    required this.reactionCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalistPost.fromJson(Map<String, dynamic> json) => JournalistPost(
        id: json['id'] as String,
        journalistId: json['journalistId'] as String,
        journalistName: json['journalistName'] as String? ?? 'Unknown',
        journalistAvatarUrl: json['journalistAvatarUrl'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        title: json['title'] as String,
        body: json['body'] as String,
        imageUrl: json['imageUrl'] as String?,
        category: json['category'] as String? ?? 'general',
        viewCount: json['viewCount'] as int? ?? 0,
        commentCount: json['commentCount'] as int? ?? 0,
        reactionCount: json['reactionCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String body;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.body,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as String,
        postId: json['postId'] as String,
        authorId: json['authorId'] as String,
        authorName: json['authorName'] as String? ?? 'Anonymous',
        authorAvatar: json['authorAvatar'] as String?,
        body: json['body'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class JournalistProfile {
  final String id;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
  final int followerCount;
  final int postCount;
  final List<Map<String, dynamic>> badges;
  final List<JournalistPost> recentPosts;

  const JournalistProfile({
    required this.id,
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.isVerified,
    required this.followerCount,
    required this.postCount,
    required this.badges,
    required this.recentPosts,
  });

  factory JournalistProfile.fromJson(Map<String, dynamic> json) => JournalistProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        bio: json['bio'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        isVerified: json['isVerified'] as bool? ?? false,
        followerCount: json['followerCount'] as int? ?? 0,
        postCount: json['postCount'] as int? ?? 0,
        badges: (json['badges'] as List<dynamic>?)
                ?.map((b) => b as Map<String, dynamic>)
                .toList() ??
            [],
        recentPosts: (json['recentPosts'] as List<dynamic>?)
                ?.map((p) => JournalistPost.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
