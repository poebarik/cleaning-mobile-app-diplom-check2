import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/network/dio_client.dart';
import '../../../data/datasources/remote/marketplace_api.dart';
import '../../../core/constants/api_constants.dart';
import '../../data/models/order/marketplace_order.dart';

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier();
});

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  late final MarketplaceApi _marketplaceApi;

  MarketplaceNotifier() : super(const MarketplaceStateInitial()) {
    _marketplaceApi = MarketplaceApi(DioClient.instance);
  }

  Future<void> createMarketplaceOrder(Map<String, dynamic> data) async {
    state = const MarketplaceStateLoading();
    try {
      final order = await _marketplaceApi.createMarketplaceOrder(data);
      state = MarketplaceStateCreated(order);
    } catch (e) {
      state = MarketplaceStateError(e.toString());
    }
  }

  Future<void> loadOpenOrders() async {
    state = const MarketplaceStateLoading();
    try {
      final orders = await _marketplaceApi.getOpenOrders();
      state = MarketplaceStateOrdersLoaded(orders);
    } catch (e) {
      state = MarketplaceStateError(e.toString());
    }
  }
}

// Состояния
sealed class MarketplaceState {
  const MarketplaceState();
}

class MarketplaceStateInitial extends MarketplaceState {
  const MarketplaceStateInitial();
}

class MarketplaceStateLoading extends MarketplaceState {
  const MarketplaceStateLoading();
}

class MarketplaceStateOrdersLoaded extends MarketplaceState {
  final List<MarketplaceOrder> orders;
  const MarketplaceStateOrdersLoaded(this.orders);
}

class MarketplaceStateCreated extends MarketplaceState {
  final MarketplaceOrder order;
  const MarketplaceStateCreated(this.order);
}

class MarketplaceStateError extends MarketplaceState {
  final String error;
  const MarketplaceStateError(this.error);
}

// Extension для удобной работы
extension MarketplaceStateExtension on MarketplaceState {
  bool get isLoading => this is MarketplaceStateLoading;
  bool get isCreated => this is MarketplaceStateCreated;
  bool get isOrdersLoaded => this is MarketplaceStateOrdersLoaded;

  List<MarketplaceOrder>? get orders {
    if (this is MarketplaceStateOrdersLoaded) {
      return (this as MarketplaceStateOrdersLoaded).orders;
    }
    return null;
  }

  MarketplaceOrder? get order {
    if (this is MarketplaceStateCreated) {
      return (this as MarketplaceStateCreated).order;
    }
    return null;
  }

  String? get error {
    if (this is MarketplaceStateError) {
      return (this as MarketplaceStateError).error;
    }
    return null;
  }
}