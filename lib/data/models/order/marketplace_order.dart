import 'order_response.dart';

class MarketplaceOrder {
  final int id;
  final int clientId;
  final String clientName;
  final String serviceName;
  final String address;
  final String? description;
  final DateTime orderDate;
  final String status;
  final double? budget;
  final int? responseDeadlineDays;
  final List<OrderResponse> responses;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool? isDirectInvitation;
  final int? invitationId;
  final List<String>? imageObjectNames;

  MarketplaceOrder({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.serviceName,
    required this.address,
    this.description,
    required this.orderDate,
    required this.status,
    this.budget,
    this.responseDeadlineDays,
    this.responses = const [],
    required this.createdAt,
    this.updatedAt,
    this.isDirectInvitation,
    this.invitationId,
    this.imageObjectNames,
  });

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrder(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      serviceName: json['serviceName'] as String,
      address: json['address'] as String,
      description: json['description'] as String?,
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : DateTime.now(),
      status: json['status'] as String,
      budget: (json['budget'] as num?)?.toDouble(),
      responseDeadlineDays: json['responseDeadlineDays'] as int?,
      responses: json['responses'] != null
          ? (json['responses'] as List)
          .map((e) => OrderResponse.fromJson(e))
          .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isDirectInvitation: json['isDirectInvitation'] as bool?,
      invitationId: json['invitationId'] as int?,
      imageObjectNames: json['imageObjectNames'] != null
          ? List<String>.from(json['imageObjectNames'])
          : null,
    );
  }
}