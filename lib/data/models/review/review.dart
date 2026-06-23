// lib/data/models/review/review.dart
class Review {
  final int id;
  final int? orderId;
  final int? authorId;
  final String authorName;
  final int? targetUserId;
  final String? clientName;
  final String? cleanerName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String reviewType;
  final String? imageUrl;
  final String? authorAvatarUrl;
  final String? targetAvatarUrl;
  final List<String>? imageObjectNames;

  Review({
    required this.id,
    this.orderId,
    this.authorId,
    required this.authorName,
    this.targetUserId,
    this.clientName,
    this.cleanerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewType,
    this.imageUrl,
    this.authorAvatarUrl,
    this.targetAvatarUrl,
    this.imageObjectNames,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    print('📦 Парсинг отзыва: ${json['id']} - ${json['authorName']}');

    // ✅ Получаем имя автора из разных полей
    String authorName = json['authorName'] as String? ?? '';
    if (authorName.isEmpty) {
      authorName = json['clientName'] as String? ?? '';
    }
    if (authorName.isEmpty) {
      authorName = json['cleanerName'] as String? ?? '';
    }
    if (authorName.isEmpty) {
      authorName = 'Пользователь';
    }

    return Review(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int?,
      authorId: json['authorId'] as int?,
      authorName: authorName,
      targetUserId: json['targetUserId'] as int?,
      clientName: json['clientName'] as String?,
      cleanerName: json['cleanerName'] as String?,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      reviewType: json['reviewType'] as String? ?? 'CLIENT_TO_CLEANER',
      imageUrl: json['imageUrl'] as String?,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      targetAvatarUrl: json['targetAvatarUrl'] as String?,
      imageObjectNames: json['imageObjectNames'] != null
          ? List<String>.from(json['imageObjectNames'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'authorId': authorId,
      'authorName': authorName,
      'targetUserId': targetUserId,
      'clientName': clientName,
      'cleanerName': cleanerName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'reviewType': reviewType,
      'imageUrl': imageUrl,
      'authorAvatarUrl': authorAvatarUrl,
      'targetAvatarUrl': targetAvatarUrl,
      'imageObjectNames': imageObjectNames,
    };
  }
}