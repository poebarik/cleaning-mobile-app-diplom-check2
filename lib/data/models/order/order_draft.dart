// lib/data/models/order/order_draft.dart
import 'package:uuid/uuid.dart';

class OrderDraft {
  final String id;
  final int serviceId;
  final String? serviceName;  // ✅ Добавляем поле
  final String address;
  final DateTime orderDate;
  final int? cleanerId;
  final String? creationType;
  final String? pricingMode;
  final double? fixedPrice;
  final String locationType;
  final String? locationCustom;
  final String cleaningType;
  final int? area;
  final List<String> rooms;
  final String? roomsCustom;
  final List<String> additionalServices;
  final List<String> customServices;
  final String inventory;
  final double? maxPrice;
  final String? notes;
  final List<String> imageObjectNames;
  final DateTime updatedAt;

  OrderDraft({
    required this.id,
    required this.serviceId,
    required this.address,
    required this.orderDate,
    required this.updatedAt,
    this.serviceName,  // ✅ Добавляем
    this.cleanerId,
    this.creationType,
    this.pricingMode,
    this.fixedPrice,
    this.locationType = 'APARTMENT',
    this.locationCustom,
    this.cleaningType = 'MAINTENANCE',
    this.area,
    this.rooms = const [],
    this.roomsCustom,
    this.additionalServices = const [],
    this.customServices = const [],
    this.inventory = 'CLIENT',
    this.maxPrice,
    this.notes,
    this.imageObjectNames = const [],
  });

  factory OrderDraft.empty() {
    return OrderDraft(
      id: const Uuid().v4(),
      serviceId: 1,
      address: '',
      orderDate: DateTime.now().add(const Duration(days: 1)),
      updatedAt: DateTime.now(),
    );
  }

  bool get hasData {
    return address.isNotEmpty ||
        cleaningType != 'MAINTENANCE' ||
        area != null ||
        rooms.isNotEmpty ||
        serviceName != null;  // ✅ Добавляем проверку
  }

  bool get isValid {
    if (creationType == null) return false;
    if (creationType == 'limitedBids' || creationType == 'openMarket') {
      if (pricingMode == null) return false;
      if (pricingMode == 'fixed' && fixedPrice == null) return false;
    }
    return true;
  }

  OrderDraft copyWith({
    String? id,
    int? serviceId,
    String? serviceName,  // ✅ Добавляем
    String? address,
    DateTime? orderDate,
    int? cleanerId,
    String? creationType,
    String? pricingMode,
    double? fixedPrice,
    String? locationType,
    String? locationCustom,
    String? cleaningType,
    int? area,
    List<String>? rooms,
    String? roomsCustom,
    List<String>? additionalServices,
    List<String>? customServices,
    String? inventory,
    double? maxPrice,
    String? notes,
    List<String>? imageObjectNames,
    DateTime? updatedAt,
  }) {
    return OrderDraft(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,  // ✅ Добавляем
      address: address ?? this.address,
      orderDate: orderDate ?? this.orderDate,
      updatedAt: updatedAt ?? DateTime.now(),
      cleanerId: cleanerId ?? this.cleanerId,
      creationType: creationType ?? this.creationType,
      pricingMode: pricingMode ?? this.pricingMode,
      fixedPrice: fixedPrice ?? this.fixedPrice,
      locationType: locationType ?? this.locationType,
      locationCustom: locationCustom ?? this.locationCustom,
      cleaningType: cleaningType ?? this.cleaningType,
      area: area ?? this.area,
      rooms: rooms ?? this.rooms,
      roomsCustom: roomsCustom ?? this.roomsCustom,
      additionalServices: additionalServices ?? this.additionalServices,
      customServices: customServices ?? this.customServices,
      inventory: inventory ?? this.inventory,
      maxPrice: maxPrice ?? this.maxPrice,
      notes: notes ?? this.notes,
      imageObjectNames: imageObjectNames ?? this.imageObjectNames,
    );
  }

  factory OrderDraft.fromJson(Map<String, dynamic> json) {
    return OrderDraft(
      id: json['id'] ?? '',
      serviceId: json['serviceId'] ?? 0,
      serviceName: json['serviceName'],  // ✅ Добавляем
      address: json['address'] ?? '',
      orderDate: DateTime.parse(json['orderDate']),
      updatedAt: DateTime.parse(json['updatedAt']),
      cleanerId: json['cleanerId'],
      creationType: json['creationType'],
      pricingMode: json['pricingMode'],
      fixedPrice: (json['fixedPrice'] as num?)?.toDouble(),
      locationType: json['locationType'] ?? 'APARTMENT',
      locationCustom: json['locationCustom'],
      cleaningType: json['cleaningType'] ?? 'MAINTENANCE',
      area: json['area'],
      rooms: List<String>.from(json['rooms'] ?? []),
      roomsCustom: json['roomsCustom'],
      additionalServices: List<String>.from(json['additionalServices'] ?? []),
      customServices: List<String>.from(json['customServices'] ?? []),
      inventory: json['inventory'] ?? 'CLIENT',
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      notes: json['notes'],
      imageObjectNames: List<String>.from(json['imageObjectNames'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'serviceName': serviceName,  // ✅ Добавляем
      'address': address,
      'orderDate': orderDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'cleanerId': cleanerId,
      'creationType': creationType,
      'pricingMode': pricingMode,
      'fixedPrice': fixedPrice,
      'locationType': locationType,
      'locationCustom': locationCustom,
      'cleaningType': cleaningType,
      'area': area,
      'rooms': rooms,
      'roomsCustom': roomsCustom,
      'additionalServices': additionalServices,
      'customServices': customServices,
      'inventory': inventory,
      'maxPrice': maxPrice,
      'notes': notes,
      'imageObjectNames': imageObjectNames,
    };
  }
}