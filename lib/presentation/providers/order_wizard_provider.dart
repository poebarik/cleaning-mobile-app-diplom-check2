// lib/presentation/providers/order_wizard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order/unified_order_request.dart';

// Enums for wizard steps
enum OrderCreationType { limitedBids, openMarket, companyAssigned }
enum PricingMode { fixed, bidding }

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
    );
  }

  bool get isValid {
    if (address.isEmpty) return false;
    if (orderDate.isBefore(DateTime.now())) return false;
    if (creationType == null) return false;
    if (creationType == OrderCreationType.limitedBids ||
        creationType == OrderCreationType.openMarket) {
      if (pricingMode == null) return false;
      if (pricingMode == PricingMode.fixed && fixedPrice == null) return false;
    }
    return true;
  }

  String get fulfillmentType {
    switch (creationType) {
      case OrderCreationType.limitedBids:
      case OrderCreationType.openMarket:
        return 'MARKETPLACE';
      case OrderCreationType.companyAssigned:
        return 'COMPANY_ASSIGNED';
      default:
        return 'MARKETPLACE';
    }
  }

  UnifiedOrderRequest toRequest() {
    print('📸 Creating order request with images: $imageObjectNames');
    print('📍 Location type: $locationType, custom: $locationCustom');

    return UnifiedOrderRequest(
      serviceId: serviceId,
      address: address,
      orderDate: orderDate,
      fulfillmentType: fulfillmentType,
      cleanerId: cleanerId,
      budget: pricingMode == PricingMode.fixed ? fixedPrice : null,
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

  void updateCreationType(OrderCreationType type) {
    state = state.copyWith(creationType: type);
  }

  void updatePricingMode(PricingMode mode, {double? fixedPrice}) {
    state = state.copyWith(pricingMode: mode, fixedPrice: fixedPrice);
  }

  void updateLocationType(String type, [String? custom]) {
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
    state = state.copyWith(
      locationType: 'CUSTOM',
      locationCustom: custom.isNotEmpty ? custom : null,
    );
  }

  void updateCleaningType(String type) {
    state = state.copyWith(cleaningType: type);
  }

  void updateArea(int? area) {
    state = state.copyWith(area: area);
  }

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
    state = state.copyWith(roomsCustom: custom);
  }

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

  void updateInventory(String inventory) {
    state = state.copyWith(inventory: inventory);
  }

  void updateMaxPrice(double? price) {
    state = state.copyWith(maxPrice: price);
  }

  void updateNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  void updateAddress(String address) {
    state = state.copyWith(address: address);
  }

  void updateOrderDate(DateTime date) {
    state = state.copyWith(orderDate: date);
  }

  void updateImages(List<String> images) {
    print('📸 Updating images in wizard: $images');
    state = state.copyWith(imageObjectNames: images);
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