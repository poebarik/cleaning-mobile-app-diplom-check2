import 'package:cleaning_mobile_application/presentation/providers/usecase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/usecases/order/create_company_order_usecase.dart';
import '../../domain/usecases/order/get_client_orders_usecase.dart';
import '../../domain/usecases/order/update_order_status_usecase.dart';
import '../../domain/entities/order_entity.dart';

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  final createCompanyOrder = ref.read(createCompanyOrderUseCaseProvider);
  final getClientOrders = ref.read(getClientOrdersUseCaseProvider);
  final updateOrderStatus = ref.read(updateOrderStatusUseCaseProvider);
  return OrderNotifier(createCompanyOrder, getClientOrders, updateOrderStatus);
});

class OrderNotifier extends StateNotifier<OrderState> {
  final CreateCompanyOrderUseCase _createCompanyOrder;
  final GetClientOrdersUseCase _getClientOrders;
  final UpdateOrderStatusUseCase _updateOrderStatus;

  OrderNotifier(
      this._createCompanyOrder,
      this._getClientOrders,
      this._updateOrderStatus,
      ) : super(const OrderStateInitial());

  Future<void> createCompanyOrder(Map<String, dynamic> data) async {
    state = const OrderStateLoading();
    final result = await _createCompanyOrder.execute(data);
    result.fold(
          (failure) => state = OrderStateError(failure.message),
          (order) => state = OrderStateCreated(order),
    );
  }

  Future<void> loadClientOrders() async {
    state = const OrderStateLoading();
    final result = await _getClientOrders.execute();
    result.fold(
          (failure) => state = OrderStateError(failure.message),
          (orders) => state = OrderStateLoaded(orders),
    );
  }

  Future<void> updateStatus(int orderId, String status) async {
    final result = await _updateOrderStatus.execute(orderId, status);
    result.fold(
          (failure) => state = OrderStateError(failure.message),
          (order) => state = OrderStateStatusUpdated(order),
    );
  }
}

// Состояния
sealed class OrderState {
  const OrderState();
}

class OrderStateInitial extends OrderState {
  const OrderStateInitial();
}

class OrderStateLoading extends OrderState {
  const OrderStateLoading();
}

class OrderStateLoaded extends OrderState {
  final List<OrderEntity> orders;
  const OrderStateLoaded(this.orders);
}

class OrderStateCreated extends OrderState {
  final OrderEntity order;
  const OrderStateCreated(this.order);
}

class OrderStateStatusUpdated extends OrderState {
  final OrderEntity order;
  const OrderStateStatusUpdated(this.order);
}

class OrderStateError extends OrderState {
  final String error;
  const OrderStateError(this.error);
}

// Extension для удобной работы
extension OrderStateExtension on OrderState {
  bool get isLoading => this is OrderStateLoading;
  bool get isLoaded => this is OrderStateLoaded;
  bool get isCreated => this is OrderStateCreated;
  bool get isStatusUpdated => this is OrderStateStatusUpdated;
  bool get isError => this is OrderStateError;

  List<OrderEntity>? get orders {
    if (this is OrderStateLoaded) {
      return (this as OrderStateLoaded).orders;
    }
    return null;
  }

  OrderEntity? get order {
    if (this is OrderStateCreated) {
      return (this as OrderStateCreated).order;
    }
    if (this is OrderStateStatusUpdated) {
      return (this as OrderStateStatusUpdated).order;
    }
    return null;
  }

  String? get error {
    if (this is OrderStateError) {
      return (this as OrderStateError).error;
    }
    return null;
  }
}