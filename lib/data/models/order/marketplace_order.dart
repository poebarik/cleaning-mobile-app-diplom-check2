class MarketplaceOrder {
  final int? id;
  final int? clientId;
  final String serviceName;
  final String address;
  final DateTime orderDate;
  final String? description;
  final double budget;
  final int responseDeadlineDays;
  final String status;
  final List<dynamic>? responses;
  final int? selectedResponseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MarketplaceOrder({
    this.id,
    this.clientId,
    required this.serviceName,
    required this.address,
    required this.orderDate,
    this.description,
    required this.budget,
    required this.responseDeadlineDays,
    required this.status,
    this.responses,
    this.selectedResponseId,
    this.createdAt,
    this.updatedAt,
  });

  factory MarketplaceOrder.fromJson(Map<String, dynamic> json) {
    return MarketplaceOrder(
      id: json['id'],
      clientId: json['clientId'],
      serviceName: json['serviceName'] ?? '',
      address: json['address'] ?? '',
      orderDate: json['orderDate'] != null ? DateTime.parse(json['orderDate']) : DateTime.now(),
      description: json['description'],
      budget: (json['budget'] ?? 0).toDouble(),
      responseDeadlineDays: json['responseDeadlineDays'] ?? 1,
      status: json['status'] ?? 'OPEN',
      responses: json['responses'],
      selectedResponseId: json['selectedResponseId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'serviceName': serviceName,
      'address': address,
      'orderDate': orderDate.toIso8601String(),
      'description': description,
      'budget': budget,
      'responseDeadlineDays': responseDeadlineDays,
      'status': status,
      'responses': responses,
      'selectedResponseId': selectedResponseId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}