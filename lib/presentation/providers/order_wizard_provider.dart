// lib/presentation/providers/order_wizard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order/unified_order_request.dart';
import '../../data/models/order/order_specification_dto.dart';

// Enums for wizard steps
enum PricingMode { fixed, bidding }
enum OrderCreationType { limitedBids, openMarket, companyAssigned, directInvitation }

class OrderWizardState {
  // Step 1: Preferences
  final OrderCreationType? creationType;

  // Step 2: Pricing Strategy
  final PricingMode? pricingMode;
  final double? fixedPrice;

  // Step 3: Location
  final String locationType;
  final String? locationCustom;

  // Step 4: Cleaning Type
  final String cleaningType;

  // Step 5: Area
  final int? area;

  // Step 6: Rooms
  final List<String> rooms;
  final String? roomsCustom;

  // Step 7: Additional Services
  final List<String> additionalServices;
  final List<String> customServices;

  // Step 8: Inventory
  final String inventory;

  // Step 9: Price Limit (for bidding mode)
  final double? maxPrice;

  // Step 10: Notes & Images
  final String? notes;
  final List<String> imageObjectNames;

  // Common fields
  final int serviceId;
  final String address;
  final DateTime orderDate;
  final int? cleanerId;

  // ✅ Добавляем название услуги
  final String? serviceName;

  const OrderWizardState({
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
    required this.serviceId,
    required this.address,
    required this.orderDate,
    this.cleanerId,
    this.serviceName,
  });

  OrderWizardState copyWith({
    OrderCreationType? creationType,
    PricingMode? pricingMode,
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
    int? serviceId,
    String? address,
    DateTime? orderDate,
    int? cleanerId,
    String? serviceName, // ✅ Добавляем
  }) {
    return OrderWizardState(
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
      serviceId: serviceId ?? this.serviceId,
      address: address ?? this.address,
      orderDate: orderDate ?? this.orderDate,
      cleanerId: cleanerId ?? this.cleanerId,
      serviceName: serviceName ?? this.serviceName, // ✅ Добавляем
    );
  }

  bool get isValid {
    if (address.isEmpty) {
      print('❌ Address is empty');
      return false;
    }
    if (orderDate.isBefore(DateTime.now())) {
      print('❌ Order date is in the past');
      return false;
    }
    if (creationType == null) {
      print('❌ Creation type is null');
      return false;
    }

    // Для MARKETPLACE
    if (creationType == OrderCreationType.limitedBids ||
        creationType == OrderCreationType.openMarket) {
      if (pricingMode == null) {
        print('❌ Pricing mode is null for MARKETPLACE');
        return false;
      }
      if (pricingMode == PricingMode.fixed && fixedPrice == null) {
        print('❌ Fixed price is null for FIXED mode');
        return false;
      }
    }

    // Для DIRECT_INVITATION - cleanerId может быть null ДО выбора клинера
    if (creationType == OrderCreationType.directInvitation) {
      print('⚠️ DIRECT_INVITATION - cleanerId will be set later');
      return true;
    }

    print('✅ Order is valid');
    return true;
  }

  String get fulfillmentType {
    final type = creationType;
    print('🔍 Computing fulfillmentType for: $type');

    switch (type) {
      case OrderCreationType.limitedBids:
      case OrderCreationType.openMarket:
        return 'MARKETPLACE';
      case OrderCreationType.companyAssigned:
        return 'COMPANY_ASSIGNED';
      case OrderCreationType.directInvitation:
        return 'DIRECT_INVITATION';
      default:
        return 'MARKETPLACE';
    }
  }

  UnifiedOrderRequest toRequest() {
    print('📸 Creating order request');
    print('  - creationType: $creationType');
    print('  - fulfillmentType: $fulfillmentType');
    print('  - cleanerId: $cleanerId');
    print('  - fixedPrice: $fixedPrice');
    print('  - maxPrice: $maxPrice');

    double? budgetValue;
    if (creationType == OrderCreationType.directInvitation) {
      budgetValue = fixedPrice ?? maxPrice ?? 0;
    } else if (pricingMode == PricingMode.fixed) {
      budgetValue = fixedPrice;
    } else if (pricingMode == PricingMode.bidding) {
      budgetValue = maxPrice;
    }

    print('  - computed budget: $budgetValue');

    return UnifiedOrderRequest(
      serviceId: serviceId,
      address: address,
      orderDate: orderDate,
      fulfillmentType: fulfillmentType,
      cleanerId: cleanerId,
      budget: budgetValue,
      description: notes,
      imageObjectNames: imageObjectNames.isNotEmpty ? imageObjectNames : null,
      specification: OrderSpecification(
        locationType: locationType,
        locationCustom: locationType == 'CUSTOM'
            ? (locationCustom?.isNotEmpty == true ? locationCustom : 'Другое')
            : null,
        area: area,
        cleaningType: cleaningType,
        rooms: rooms,
        roomsCustom: roomsCustom,
        additionalServices: additionalServices,
        customServices: customServices,
        inventory: inventory,
        pricingMode: pricingMode == PricingMode.fixed ? 'FIXED' : 'BIDDING',
        price: fixedPrice,
        maxPrice: maxPrice,
        notes: notes,
        roomsCount: null,
        bathrooms: null,
        hasPets: null,
      ),
    );
  }
}

class OrderWizardNotifier extends StateNotifier<OrderWizardState> {
  OrderWizardNotifier({
    required int serviceId,
    required String address,
    required DateTime orderDate,
    int? cleanerId,
  }) : super(OrderWizardState(
    serviceId: serviceId,
    address: address,
    orderDate: orderDate,
    cleanerId: cleanerId,
  ));

  // ─── Обновление типа создания ──────────────────────────────────
  void updateCreationType(OrderCreationType type) {
    print('🔍 Updating creation type to: $type');
    state = state.copyWith(creationType: type);
  }

  // ─── Обновление способа ценообразования ──────────────────────
  void updatePricingMode(PricingMode mode, {double? fixedPrice}) {
    print('📸 updatePricingMode: $mode, fixedPrice: $fixedPrice');
    state = state.copyWith(
      pricingMode: mode,
      fixedPrice: fixedPrice,
    );
  }

  // ─── Обновление типа локации ──────────────────────────────────
  void updateLocationType(String type, [String? custom]) {
    print('📸 updateLocationType: $type, custom: $custom');
    if (type != 'CUSTOM') {
      state = state.copyWith(
        locationType: type,
        locationCustom: null,
      );
    } else {
      state = state.copyWith(
        locationType: type,
        locationCustom: custom ?? state.locationCustom,
      );
    }
  }

  void updateLocationCustom(String custom) {
    print('📸 updateLocationCustom: $custom');
    state = state.copyWith(
      locationType: 'CUSTOM',
      locationCustom: custom.isNotEmpty ? custom : null,
    );
  }

  // ─── Обновление типа уборки ──────────────────────────────────
  void updateCleaningType(String cleaningType) {
    print('📸 updateCleaningType: $cleaningType');
    state = state.copyWith(cleaningType: cleaningType);
  }

  // ─── Обновление площади ──────────────────────────────────────
  void updateArea(int? area) {
    print('📸 updateArea: $area');
    state = state.copyWith(area: area);
  }

  // ─── Обновление комнат ────────────────────────────────────────
  void toggleRoom(String room) {
    final newRooms = List<String>.from(state.rooms);
    if (newRooms.contains(room)) {
      newRooms.remove(room);
    } else {
      newRooms.add(room);
    }
    state = state.copyWith(rooms: newRooms);
  }

  void updateRoomsCustom(String? custom) {
    print('📸 updateRoomsCustom: $custom');
    state = state.copyWith(roomsCustom: custom);
  }

  // ─── Обновление дополнительных услуг ────────────────────────
  void toggleAdditionalService(String service) {
    final newServices = List<String>.from(state.additionalServices);
    if (newServices.contains(service)) {
      newServices.remove(service);
    } else {
      newServices.add(service);
    }
    state = state.copyWith(additionalServices: newServices);
  }

  void addCustomService(String service) {
    final newServices = List<String>.from(state.customServices);
    newServices.add(service);
    state = state.copyWith(customServices: newServices);
  }

  void removeCustomService(String service) {
    final newServices = List<String>.from(state.customServices);
    newServices.remove(service);
    state = state.copyWith(customServices: newServices);
  }

  // ─── Обновление инвентаря ────────────────────────────────────
  void updateInventory(String inventory) {
    print('📸 updateInventory: $inventory');
    state = state.copyWith(inventory: inventory);
  }

  // ─── Обновление максимальной цены ────────────────────────────
  void updateMaxPrice(double? price) {
    print('📸 updateMaxPrice: $price');
    state = state.copyWith(maxPrice: price);
  }

  // ─── Обновление заметок ──────────────────────────────────────
  void updateNotes(String? notes) {
    print('📸 updateNotes: $notes');
    state = state.copyWith(notes: notes);
  }

  // ─── Обновление адреса ────────────────────────────────────────
  void updateAddress(String address) {
    print('📸 updateAddress: $address');
    state = state.copyWith(address: address);
  }

  // ─── Обновление даты ─────────────────────────────────────────
  void updateOrderDate(DateTime date) {
    print('📸 updateOrderDate: $date');
    state = state.copyWith(orderDate: date);
  }

  // ─── Обновление изображений ──────────────────────────────────
  void updateImages(List<String> images) {
    print('📸 updateImages: $images');
    state = state.copyWith(imageObjectNames: images);
  }

  // ─── Обновление ID услуги ────────────────────────────────────
  void updateServiceId(int serviceId) {
    print('📸 updateServiceId: $serviceId');
    state = state.copyWith(serviceId: serviceId);
  }

  // ─── Обновление фиксированной цены ──────────────────────────
  void updateFixedPrice(double price) {
    print('📸 updateFixedPrice: $price');
    state = state.copyWith(fixedPrice: price);
  }

  // ─── Обновление ID клинера ──────────────────────────────────
  void updateCleanerId(int? cleanerId) {
    print('📸 updateCleanerId: $cleanerId');
    state = state.copyWith(cleanerId: cleanerId);
  }

  // ✅ НОВЫЙ МЕТОД: Обновление названия услуги
  void updateServiceName(String? serviceName) {
    print('📸 updateServiceName: $serviceName');
    state = state.copyWith(serviceName: serviceName);
  }
}

// Provider factory
OrderWizardNotifier createOrderWizardNotifier({
  required int serviceId,
  required String address,
  required DateTime orderDate,
  int? cleanerId,
}) {
  return OrderWizardNotifier(
    serviceId: serviceId,
    address: address,
    orderDate: orderDate,
    cleanerId: cleanerId,
  );
}

// ✅ Provider для доступа к состоянию заказа
final orderWizardProvider = StateNotifierProvider<OrderWizardNotifier, OrderWizardState>((ref) {
  // Этот провайдер будет переопределен при создании
  throw UnimplementedError('Use createOrderWizardNotifier factory');
});