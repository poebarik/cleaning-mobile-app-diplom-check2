import 'package:dio/dio.dart';
import '../../domain/enums/order_action.dart';
import '../models/order/order.dart';
import '../models/order/unified_order_request.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class OrderRepository {
  final Dio _dio = DioClient.instance;

  // ✅ Создание заказа
  Future<Order> createOrderWithMode(UnifiedOrderRequest request) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.createOrderWithMode}',
      data: request.toJson(),
    );
    return Order.fromJson(response.data);
  }

  // ✅ Выполнение действия над заказом - РАБОТАЕТ
  Future<void> executeAction(
      int orderId,
      OrderAction action,
      Map<String, dynamic> payload,
      ) async {
    final url = '/orders/$orderId/action';

    print('📡 Executing action: ${action.value} on order $orderId');
    print('📦 Payload: $payload');
    print('🔗 Full URL: ${ApiConstants.baseUrl}$url');

    final response = await _dio.post(
      '${ApiConstants.baseUrl}$url',
      data: {
        'action': action.value,
        'payload': payload,
      },
    );

    print('✅ Action executed successfully, status: ${response.statusCode}');
  }

  // ✅ Получение открытых маркетплейс заказов
  Future<List<Order>> getOpenMarketplaceOrders() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/marketplace/orders/open',
    );
    return (response.data as List).map((e) => Order.fromJson(e)).toList();
  }

  // ✅ Получение заказов клиента
  Future<List<Order>> getClientOrders() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.clientOrders}',
    );
    return (response.data as List).map((e) => Order.fromJson(e)).toList();
  }

  // ✅ Получение заказов клинера
  Future<List<Order>> getCleanerOrders() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.cleanerOrders}',
    );
    return (response.data as List).map((e) => Order.fromJson(e)).toList();
  }

  // ✅ Получение деталей заказа
  Future<Order> getOrderById(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/orders/$id',
    );
    return Order.fromJson(response.data);
  }
}