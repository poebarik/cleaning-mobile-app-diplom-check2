// lib/data/models/invitation/negotiation.dart
class Negotiation {
  final int id;
  final int senderId;
  final String senderName;
  final String senderRole; // 'CLIENT' или 'CLEANER'
  final double proposedPrice;
  final String? message;
  final DateTime createdAt;
  final String? status; // 'PENDING', 'ACCEPTED', 'REJECTED'

  Negotiation({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.proposedPrice,
    this.message,
    required this.createdAt,
    this.status,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String,
      senderRole: json['senderRole'] as String,
      proposedPrice: (json['proposedPrice'] as num).toDouble(),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'proposedPrice': proposedPrice,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';
}