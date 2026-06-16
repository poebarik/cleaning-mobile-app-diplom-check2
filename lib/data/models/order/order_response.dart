// lib/data/models/order/order_response.dart

class OrderResponse {
  final int id;
  final int orderId;
  final int userId;

  final int cleanerId;
  final String cleanerName;
  final String? cleanerAvatar;

  final double? cleanerRating;
  final double priceOffer;

  final String? message;
  final String status;

  final DateTime? createdAt;

  final bool isVerified;
  final int completedOrders;
  final double rating;

  OrderResponse({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.cleanerId,
    required this.cleanerName,
    this.cleanerAvatar,
    this.cleanerRating,
    required this.priceOffer,
    this.message,
    required this.status,
    this.createdAt,
    this.isVerified = false,
    this.completedOrders = 0,
    this.rating = 0,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final cleaner = json['cleaner'];
    final cleanerUser = cleaner?['user'] as Map<String, dynamic>?;

    return OrderResponse(
      id: json['id'] as int,

      orderId: json['orderId'] as int? ??
          json['jobPostId'] as int? ??
          0,
      userId: cleanerUser?['id'] as int? ?? cleaner?['userId'] as int? ?? 0,  // ✅ userId из cleaner

      cleanerId: json['cleanerId'] as int,

      cleanerName: json['cleanerName'] as String? ??
          cleaner?['fullName'] as String? ??
          cleaner?['user']?['fullName'] as String? ??
          'Клинер',

      cleanerAvatar: json['cleanerAvatar'] as String? ??
          cleaner?['avatarUrl'] as String? ??
          cleaner?['user']?['avatarObjectName'] as String?,

      cleanerRating:
      (json['cleanerRating'] as num?)?.toDouble() ??
          (cleaner?['rating'] as num?)?.toDouble(),

      priceOffer:
      (json['priceOffer'] as num?)?.toDouble() ?? 0.0,

      message: json['message'] as String?,

      status: json['status'] as String? ?? 'PENDING',

      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,

      isVerified:
      cleaner?['verificationStatus'] == 'VERIFIED',

      completedOrders:
      cleaner?['completedOrders'] as int? ?? 0,
      rating: (cleaner?['rating'] as num?)?.toDouble() ??
          (json['cleanerRating'] as num?)?.toDouble() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'cleanerAvatar': cleanerAvatar,
      'cleanerRating': cleanerRating,
      'message': message,
      'priceOffer': priceOffer,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'isVerified': isVerified,
      'completedOrders': completedOrders,
    };
  }
}