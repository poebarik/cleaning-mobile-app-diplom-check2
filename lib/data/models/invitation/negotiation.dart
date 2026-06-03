class Negotiation {
  final int id;
  final int senderId;
  final String senderName;
  final String senderRole;
  final double proposedPrice;
  final String? message;
  final DateTime createdAt;

  Negotiation({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.proposedPrice,
    this.message,
    required this.createdAt,
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
    );
  }
}