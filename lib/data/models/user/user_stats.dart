// lib/data/models/user/user_stats.dart
class UserStats {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double averageRating;
  final int reviewsCount;

  UserStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageRating,
    required this.reviewsCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalOrders: json['totalOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
    );
  }
}