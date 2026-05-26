class Order {
  final int id;
  final int clientId;
  final int? cleanerId;
  final int serviceId;
  final String serviceName;
  final String address;
  final DateTime orderDate;
  final String? description;
  final String orderType;
  final String status;
  final double? budget;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.clientId,
    this.cleanerId,
    required this.serviceId,
    required this.serviceName,
    required this.address,
    required this.orderDate,
    this.description,
    required this.orderType,
    required this.status,
    this.budget,
    this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      cleanerId: json['cleanerId'] as int?,
      serviceId: json['serviceId'] as int,
      serviceName: json['serviceName'] as String,
      address: json['address'] as String,
      orderDate: DateTime.parse(json['orderDate'] as String),
      description: json['description'] as String?,
      orderType: json['orderType'] as String,
      status: json['status'] as String,
      budget: (json['budget'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'cleanerId': cleanerId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'address': address,
      'orderDate': orderDate.toIso8601String(),
      'description': description,
      'orderType': orderType,
      'status': status,
      'budget': budget,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}