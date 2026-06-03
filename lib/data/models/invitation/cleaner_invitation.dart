import 'negotiation.dart';

class CleanerInvitation {
  final int id;
  final int orderId;
  final String orderAddress;
  final String serviceName;
  final int clientId;
  final String clientName;
  final int cleanerId;
  final String cleanerName;
  final double? cleanerRating;
  final double proposedPrice;
  final String? clientComment;
  final String? cleanerComment;
  final String status;
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

  factory CleanerInvitation.fromJson(Map<String, dynamic> json) {
    return CleanerInvitation(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      orderAddress: json['orderAddress'] as String,
      serviceName: json['serviceName'] as String,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      cleanerId: json['cleanerId'] as int,
      cleanerName: json['cleanerName'] as String,
      cleanerRating: (json['cleanerRating'] as num?)?.toDouble(),
      proposedPrice: (json['proposedPrice'] as num).toDouble(),
      clientComment: json['clientComment'] as String?,
      cleanerComment: json['cleanerComment'] as String?,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expiresAt']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      negotiations: json['negotiations'] != null
          ? (json['negotiations'] as List).map((e) => Negotiation.fromJson(e)).toList()
          : [],
      isExpired: json['isExpired'] as bool,
      imageObjectNames: json['imageObjectNames'] != null
          ? List<String>.from(json['imageObjectNames'])
          : null,
    );
  }
}