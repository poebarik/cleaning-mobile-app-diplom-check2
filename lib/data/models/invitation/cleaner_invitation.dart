import 'negotiation.dart';

class CleanerInvitation {
  final int id;
  final int orderId;
  final String orderAddress;
  final String serviceName;
  final int userId;
  final String status;
  final int clientId;
  final String clientName;
  final int cleanerId;
  final String cleanerName;
  final double? cleanerRating;
  final double proposedPrice;
  final String? clientComment;
  final String? cleanerComment;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Negotiation> negotiations;
  final bool isExpired;
  final List<String>? imageObjectNames;

  CleanerInvitation({
    required this.id,
    required this.orderId,
    required this.orderAddress,
    required this.serviceName,
    required this.userId,
    required this.clientId,
    required this.clientName,
    required this.cleanerId,
    required this.cleanerName,
    this.cleanerRating,
    required this.proposedPrice,
    this.clientComment,
    this.cleanerComment,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.negotiations = const [],
    required this.isExpired,

    this.imageObjectNames,
  });

// lib/data/models/invitation/cleaner_invitation.dart
  factory CleanerInvitation.fromJson(Map<String, dynamic> json) {
    print('📥 Parsing invitation: $json');

    final cleaner = json['cleaner'] as Map<String, dynamic>?;
    final user = cleaner?['user'] as Map<String, dynamic>?;

    try {
      return CleanerInvitation(
        id: json['id'] as int? ?? 0,
        orderId: json['orderId'] as int? ?? 0,
        orderAddress: json['orderAddress'] as String? ?? '',
        serviceName: json['serviceName'] as String? ?? '',  // ✅ serviceName может быть null
        userId: json['userId'] as int? ?? user?['id'] as int? ?? 0,
        clientId: json['clientId'] as int? ?? 0,
        clientName: json['clientName'] as String? ?? '',
        cleanerId: json['cleanerId'] as int? ?? 0,
        cleanerName: json['cleanerName'] as String? ?? '',
        cleanerRating: (json['cleanerRating'] as num?)?.toDouble(),
        proposedPrice: (json['proposedPrice'] as num?)?.toDouble() ?? 0,
        clientComment: json['clientComment'] as String?,  // ✅ nullable
        cleanerComment: json['cleanerComment'] as String?,  // ✅ nullable
        status: json['status'] as String? ?? 'PENDING',
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'])
            : DateTime.now().add(const Duration(days: 7)),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : DateTime.now(),
        negotiations: json['negotiations'] != null
            ? (json['negotiations'] as List).map((e) => Negotiation.fromJson(e)).toList()
            : [],
        isExpired: json['isExpired'] as bool? ?? false,
        imageObjectNames: json['imageObjectNames'] != null
            ? List<String>.from(json['imageObjectNames'])
            : null,
      );
    } catch (e, stackTrace) {
      print('❌ Error parsing invitation: $e');
      print('📄 Stack trace: $stackTrace');
      print('📄 JSON data: $json');
      rethrow;
    }
  }
}