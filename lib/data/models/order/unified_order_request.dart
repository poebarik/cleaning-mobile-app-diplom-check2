import 'package:json_annotation/json_annotation.dart';

class UnifiedOrderRequest {
  final int serviceId;
  final String address;
  final DateTime orderDate;
  final String? description;
  final String fulfillmentType; // "COMPANY_ASSIGNED" or "MARKETPLACE" or "DIRECT_INVITATION"
  final double? budget;
  final int? responseDeadlineDays;
  final List<String>? imageObjectNames;

  UnifiedOrderRequest({
    required this.serviceId,
    required this.address,
    required this.orderDate,
    this.description,
    required this.fulfillmentType,
    this.budget,
    this.responseDeadlineDays,
    this.imageObjectNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'address': address,
      'orderDate': orderDate.toIso8601String(),
      'description': description,
      'fulfillmentType': fulfillmentType,
      if (budget != null) 'budget': budget,
      if (responseDeadlineDays != null) 'responseDeadlineDays': responseDeadlineDays,
      if (imageObjectNames != null) 'imageObjectNames': imageObjectNames,
    };
  }
}