class OrderSpecificationDTO {
  // Location
  final String? locationType;
  final String? locationCustom;

  // Area
  final int? area;

  // Cleaning type
  final String? cleaningType;

  // Rooms
  final List<String>? rooms;
  final String? roomsCustom;

  // Additional services
  final List<String>? additionalServices;
  final List<String>? customServices;

  // Inventory
  final String? inventory;

  // Pricing
  final String? pricingMode;
  final double? price;
  final double? maxPrice;

  // Additional info
  final String? notes;
  final int? roomsCount;
  final int? bathrooms;
  final bool? hasPets;

  // ✅ Добавляем поле для фото
  final List<String>? imageObjectNames;

  OrderSpecificationDTO({
    this.locationType,
    this.locationCustom,
    this.area,
    this.cleaningType,
    this.rooms,
    this.roomsCustom,
    this.additionalServices,
    this.customServices,
    this.inventory,
    this.pricingMode,
    this.price,
    this.maxPrice,
    this.notes,
    this.roomsCount,
    this.bathrooms,
    this.hasPets,
    this.imageObjectNames,  // ✅ Добавляем
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'locationType': locationType,
      'locationCustom': locationCustom,
      'area': area,
      'cleaningType': cleaningType,
      'rooms': rooms,
      'roomsCustom': roomsCustom,
      'additionalServices': additionalServices,
      'customServices': customServices,
      'inventory': inventory,
      'pricingMode': pricingMode,
      'price': price,
      'maxPrice': maxPrice,
      'notes': notes,
      'roomsCount': roomsCount,
      'bathrooms': bathrooms,
      'hasPets': hasPets,
    };

    // ✅ Добавляем фото только если они есть
    if (imageObjectNames != null && imageObjectNames!.isNotEmpty) {
      json['imageObjectNames'] = imageObjectNames;
    }

    return json;
  }

  factory OrderSpecificationDTO.fromJson(Map<String, dynamic> json) {
    return OrderSpecificationDTO(
      locationType: json['locationType'] as String?,
      locationCustom: json['locationCustom'] as String?,
      area: json['area'] as int?,
      cleaningType: json['cleaningType'] as String?,
      rooms: json['rooms'] != null ? List<String>.from(json['rooms']) : null,
      roomsCustom: json['roomsCustom'] as String?,
      additionalServices: json['additionalServices'] != null ? List<String>.from(json['additionalServices']) : null,
      customServices: json['customServices'] != null ? List<String>.from(json['customServices']) : null,
      inventory: json['inventory'] as String?,
      pricingMode: json['pricingMode'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      roomsCount: json['roomsCount'] as int?,
      bathrooms: json['bathrooms'] as int?,
      hasPets: json['hasPets'] as bool?,
      imageObjectNames: json['imageObjectNames'] != null ? List<String>.from(json['imageObjectNames']) : null,  // ✅ Добавляем
    );
  }
}