// lib/data/models/review/create_review_request.dart

class CreateReviewRequest {
  final int orderId;
  final int targetUserId;      // ✅ УЖЕ ЕСТЬ В КОНСТРУКТОРЕ
  final int rating;
  final String comment;
  final String reviewType;
  final List<String>? imageObjectNames;

  CreateReviewRequest({
    required this.orderId,
    required this.targetUserId,
    required this.rating,
    required this.comment,
    required this.reviewType,
    this.imageObjectNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'targetUserId': targetUserId,  // ✅ ДОБАВИТЬ ЭТУ СТРОКУ!
      'rating': rating,
      'comment': comment,
      'imageObjectNames': imageObjectNames ?? [],
      'reviewType': reviewType,
    };
  }
}