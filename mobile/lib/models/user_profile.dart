/// Dart model for the UserProfile type.
/// Mirrors web/src/types/index.ts → UserProfile exactly.
class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String createdAt;
  final String role;
  final String? journalistId;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.role = 'user',
    this.journalistId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] as String,
      role: json['role'] as String? ?? 'user',
      journalistId: json['journalistId'] as String?,
    );
  }

  bool get isJournalist => role == 'journalist';
  bool get isAdmin => role == 'admin';
  bool get isBanned => role == 'banned';

  /// Returns the best available display name, falling back to email prefix.
  String get name => displayName ?? email.split('@').first;

  /// Returns the first letter of the display name for avatar placeholders.
  String get initials => name[0].toUpperCase();
}
