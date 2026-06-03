class Order {
  final int id;
  final int? clientId;           // ✅ nullable
  final String clientName;
  final int? cleanerId;
  final String? cleanerName;
  final int? serviceId;          // ✅ nullable
  final String serviceName;
  final double servicePrice;
  final String address;
  final DateTime orderDate;
  final String status;
  final String? description;
  final String orderType;
  final double? budget;
  final DateTime createdAt;
  final DateTime? updatedAt;

  final bool? isDirectInvitation;
  final int? invitationId;
  final List<String>? imageObjectNames;

  Order({
    required this.id,
    this.clientId,
    required this.clientName,
    this.cleanerId,
    this.cleanerName,
    this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    required this.address,
    required this.orderDate,
    required this.status,
    this.description,
    required this.orderType,
    this.budget,
    required this.createdAt,
    this.updatedAt,
    this.isDirectInvitation,
    this.invitationId,
    this.imageObjectNames,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int,
      clientId: json['clientId'] as int?,
      clientName: json['clientName'] as String? ?? '',
      cleanerId: json['cleanerId'] as int?,
      cleanerName: json['cleanerName'] as String?,
      serviceId: json['serviceId'] as int?,
      serviceName: json['serviceName'] as String? ?? '',
      servicePrice: (json['servicePrice'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : DateTime.now(),
      status: json['status'] as String? ?? 'PENDING',
      description: json['description'] as String?,
      orderType: json['orderType'] as String? ?? 'COMPANY_ASSIGNED',
      budget: (json['budget'] as num?)?.toDouble(),
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'address': address,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'description': description,
      'orderType': orderType,
      'budget': budget,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isDirectInvitation': isDirectInvitation,
      'invitationId': invitationId,
      'imageObjectNames': imageObjectNames,
    };
  }
}