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

    return Review(
      id: json['id'] ?? 0,
      orderId: json['orderId'],
      authorId: json['authorId'],
      authorName: json['authorName'] ?? json['clientName'] ?? json['cleanerName'] ?? 'Пользователь',
      targetUserId: json['targetUserId'],
      clientName: json['clientName'],
      cleanerName: json['cleanerName'],
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      reviewType: json['reviewType'] ?? 'CLIENT_TO_CLEANER',
      imageUrl: json['imageUrl'],
      authorAvatarUrl: json['authorAvatarUrl'],
      targetAvatarUrl: json['targetAvatarUrl'],
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