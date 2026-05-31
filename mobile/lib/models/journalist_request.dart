class JournalistRequestStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class JournalistRequest {
  final String id;
  final String status;
  final String? message;
  final String? adminNote;
  final String createdAt;
  final String? reviewedAt;

  const JournalistRequest({
    required this.id,
    required this.status,
    this.message,
    this.adminNote,
    required this.createdAt,
    this.reviewedAt,
  });

  factory JournalistRequest.fromJson(Map<String, dynamic> json) {
    return JournalistRequest(
      id: json['id'] as String,
      status: json['status'] as String,
      message: json['message'] as String?,
      adminNote: json['adminNote'] as String?,
      createdAt: json['createdAt'] as String,
      reviewedAt: json['reviewedAt'] as String?,
    );
  }

  bool get isPending => status == JournalistRequestStatus.pending;
  bool get isApproved => status == JournalistRequestStatus.approved;
  bool get isRejected => status == JournalistRequestStatus.rejected;
}
