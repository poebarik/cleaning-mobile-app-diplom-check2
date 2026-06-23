// lib/data/models/order/order_response.dart
import '../invitation/negotiation.dart';

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
  final Negotiation? counterOffer;

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
    this.counterOffer,
  });

  // lib/data/models/order/order_response.dart

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    // Получаем cleaner объект
    final cleaner = json['cleaner'] as Map<String, dynamic>?;

    // ✅ userId берем из cleaner.userId (это настоящий ID пользователя)
    int userId = 0;
    if (cleaner != null && cleaner['userId'] != null) {
      userId = cleaner['userId'] as int;
      print('📥 userId взят из cleaner.userId: $userId');
    } else if (json['userId'] != null) {
      userId = json['userId'] as int;
      print('📥 userId взят из json.userId: $userId');
    } else {
      // Fallback - используем cleanerId
      userId = json['cleanerId'] as int;
      print('⚠️ userId не найден, используем cleanerId как fallback: $userId');
    }

    // ✅ cleanerId - берем из json['cleanerId']
    final cleanerId = json['cleanerId'] as int;

    print('📥 OrderResponse.fromJson:');
    print('  - id: ${json['id']}');
    print('  - userId (настоящий ID пользователя): $userId');
    print('  - cleanerId (ID в cleaners): $cleanerId');
    print('  - cleanerName: ${json['cleanerName']}');

    return OrderResponse(
      id: json['id'] as int,
      orderId: json['orderId'] as int? ?? json['jobPostId'] as int? ?? 0,
      userId: userId, // ✅ Это ID пользователя (3 для Анны)
      cleanerId: cleanerId, // ✅ Это ID клинера (2 для Анны)
      cleanerName: json['cleanerName'] as String? ??
          cleaner?['fullName'] as String? ??
          cleaner?['user']?['fullName'] as String? ??
          'Клинер',
      cleanerAvatar: json['cleanerAvatar'] as String? ??
          cleaner?['avatarUrl'] as String? ??
          cleaner?['user']?['avatarObjectName'] as String?,
      cleanerRating: (json['cleanerRating'] as num?)?.toDouble() ??
          (cleaner?['rating'] as num?)?.toDouble(),
      priceOffer: (json['priceOffer'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      isVerified: cleaner?['verificationStatus'] == 'VERIFIED',
      completedOrders: cleaner?['completedOrders'] as int? ?? 0,
      rating: (cleaner?['rating'] as num?)?.toDouble() ??
          (json['cleanerRating'] as num?)?.toDouble() ??
          0,
      counterOffer: json['counterOffer'] != null
          ? Negotiation.fromJson(json['counterOffer'])
          : null,
    );
  }
}