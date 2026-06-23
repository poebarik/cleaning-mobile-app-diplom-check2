// lib/data/models/order/order.dart
import 'order_response.dart';
import 'order_specification_dto.dart';

class Order {
  final int id;
  final int? clientId;
  final int? userId;
  final String clientName;
  final int? cleanerId;
  final String? cleanerName;
  final int? serviceId;
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
  final int? jobPostId;
  final OrderSpecificationDTO? specification;
  final String? clientAvatarUrl;
  final String? selectedCleanerAvatarUrl;
  final String? selectedCleanerName;
  final bool? isDirectInvitation;
  final bool? isMarketplace; // ✅ Добавляем поле
  final int? invitationId;
  final List<String>? imageObjectNames;
  final List<OrderResponse>? responses;

  Order({
    required this.id,
    this.clientId,
    this.userId,
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
    this.isMarketplace, // ✅ Добавляем в конструктор
    this.invitationId,
    this.imageObjectNames,
    this.responses,
    this.jobPostId,
    this.specification,
    this.clientAvatarUrl,
    this.selectedCleanerAvatarUrl,
    this.selectedCleanerName,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // ✅ Безопасно парсим userId с проверкой на null
    int? userId;
    if (json['userId'] != null) {
      userId = json['userId'] as int?;
    } else if (json['clientId'] != null) {
      userId = json['clientId'] as int?;
    }

    print('📦 Order.fromJson:');
    print('  - id: ${json['id']}');
    print('  - userId: $userId');
    print('  - clientName: ${json['clientName']}');

    return Order(
      id: json['id'] as int? ?? 0,
      clientId: json['clientId'] as int?,
      userId: userId,
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
      isMarketplace: json['isMarketplace'] as bool?, // ✅ Парсим
      invitationId: json['invitationId'] as int?,
      imageObjectNames: json['imageObjectNames'] != null
          ? List<String>.from(json['imageObjectNames'])
          : null,
      jobPostId: json['jobPostId'] as int?,
      responses: json['responses'] != null
          ? (json['responses'] as List)
          .map((e) => OrderResponse.fromJson(e))
          .toList()
          : [],
      specification: json['specification'] != null
          ? OrderSpecificationDTO.fromJson(json['specification'])
          : null,
      clientAvatarUrl: json['clientAvatarUrl'] as String?,
      selectedCleanerAvatarUrl: json['selectedCleanerAvatarUrl'] as String?,
      selectedCleanerName: json['selectedCleanerName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'userId': userId,
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
      'isMarketplace': isMarketplace, // ✅ Добавляем в toJson
      'invitationId': invitationId,
      'imageObjectNames': imageObjectNames,
      'clientAvatarUrl': clientAvatarUrl,
      'selectedCleanerAvatarUrl': selectedCleanerAvatarUrl,
      'selectedCleanerName': selectedCleanerName,
    };
  }
}