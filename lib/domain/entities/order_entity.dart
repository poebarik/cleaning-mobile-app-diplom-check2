import '../enums/order_status.dart';
import '../enums/order_type.dart';

class OrderEntity {
  final int id;
  final int clientId;
  final int? cleanerId;
  final String serviceName;
  final String address;
  final DateTime orderDate;
  final String? description;
  final OrderType orderType;
  final OrderStatus status;
  final double? budget;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderEntity({
    required this.id,
    required this.clientId,
    this.cleanerId,
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
}