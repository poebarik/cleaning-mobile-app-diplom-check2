// lib/data/models/review/create_review_request.dart
class CreateReviewRequest {
  final int orderId;
  final int targetUserId;
  final int rating;
  final String comment;
  final String reviewType; // "CLIENT_TO_CLEANER" или "CLEANER_TO_CLIENT"
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
    final map = <String, dynamic>{
      'orderId': orderId,
      'targetUserId': targetUserId,
      'rating': rating,
      'comment': comment,
      'reviewType': reviewType,
    };
    if (imageObjectNames != null && imageObjectNames!.isNotEmpty) {
      map['imageObjectNames'] = imageObjectNames;
    }
    return map;
  }
}