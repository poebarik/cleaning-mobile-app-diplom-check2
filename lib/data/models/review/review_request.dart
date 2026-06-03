class ReviewRequest {
  final int orderId;
  final int rating;
  final String comment;
  final List<String>? imageObjectNames;

  ReviewRequest({
    required this.orderId,
    required this.rating,
    required this.comment,
    this.imageObjectNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'imageObjectNames': imageObjectNames,
    };
  }
}