// lib/data/models/order/unified_order_request.dart
class UnifiedOrderRequest {
  // Основные поля заказа
  final int serviceId;
  final String address;
  final DateTime orderDate;
  final String fulfillmentType; // COMPANY_ASSIGNED, MARKETPLACE, DIRECT_INVITATION
  final List<String>? imageObjectNames;

  // Спецификация заказа
  final OrderSpecification specification;

  // Дополнительные поля
  final double? budget;
  final int? cleanerId; // для DIRECT_INVITATION
  final String? description; // ✅ ДОБАВЛЯЕМ НА ВЕРХНИЙ УРОВЕНЬ

  UnifiedOrderRequest({
    required this.serviceId,
    required this.address,
    required this.orderDate,
    required this.fulfillmentType,
    required this.specification,
    this.budget,
    this.cleanerId,
    this.description, // ✅ ДОБАВЛЯЕМ
    this.imageObjectNames,

  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'serviceId': serviceId,
      'address': address,
      'orderDate': orderDate.toIso8601String(),
      'fulfillmentType': fulfillmentType,
      'specification': specification.toJson(),
    };

    // ✅ ТОЛЬКО добавляем не-null значения
    if (budget != null) map['budget'] = budget;
    if (cleanerId != null) map['cleanerId'] = cleanerId;
    if (description != null && description!.isNotEmpty) map['description'] = description;
    if (imageObjectNames != null && imageObjectNames!.isNotEmpty) {
      map['imageObjectNames'] = imageObjectNames;
    }

    return map;
  }
}

// OrderSpecification остается без изменений (description внутри не нужен, но можно оставить)
class OrderSpecification {
  final String locationType;
  final String? locationCustom;
  final int? area;
  final String cleaningType;
  final List<String> rooms;
  final String? roomsCustom;
  final List<String> additionalServices;
  final List<String> customServices;
  final String inventory;
  final String pricingMode;
  final double? price;
  final double? maxPrice;
  final String? notes;
  final int? roomsCount;
  final int? bathrooms;
  final bool? hasPets;
  // final String? description; // ⚠️ МОЖНО УБРАТЬ, если не используется

  OrderSpecification({
    required this.locationType,
    this.locationCustom,
    this.area,
    required this.cleaningType,
    required this.rooms,
    this.roomsCustom,
    required this.additionalServices,
    required this.customServices,
    required this.inventory,
    required this.pricingMode,
    this.price,
    this.maxPrice,
    this.notes,
    this.roomsCount,
    this.bathrooms,
    this.hasPets,
    // this.description, // Убираем
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'locationType': locationType,
      'cleaningType': cleaningType,
      'rooms': rooms,
      'additionalServices': additionalServices,
      'customServices': customServices,
      'inventory': inventory,
      'pricingMode': pricingMode,
    };

    if (locationCustom != null && locationCustom!.isNotEmpty) {
      map['locationCustom'] = locationCustom;
    }
    if (area != null) map['area'] = area;
    if (roomsCustom != null && roomsCustom!.isNotEmpty) {
      map['roomsCustom'] = roomsCustom;
    }
    if (price != null) map['price'] = price;
    if (maxPrice != null) map['maxPrice'] = maxPrice;
    if (notes != null && notes!.isNotEmpty) {
      map['notes'] = notes;
    }
    if (roomsCount != null) map['roomsCount'] = roomsCount;
    if (bathrooms != null) map['bathrooms'] = bathrooms;
    if (hasPets != null) map['hasPets'] = hasPets;

    return map;
  }
}