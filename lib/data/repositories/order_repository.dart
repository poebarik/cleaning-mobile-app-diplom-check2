import 'dart:convert';

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
    try {
      final json = request.toJson();
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 SENDING ORDER REQUEST:');
      print('📤 URL: ${ApiConstants.baseUrl}/orders/create-with-mode');
      print('📤 Body: ${jsonEncode(json)}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/orders/create-with-mode',
        data: json,
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ RESPONSE RECEIVED:');
      print('✅ Status: ${response.statusCode}');
      print('✅ Headers: ${response.headers}');
      print('✅ Data: ${response.data}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Проверяем структуру ответа
        dynamic responseData = response.data;

        // Если ответ обернут в data
        if (responseData is Map && responseData.containsKey('data')) {
          responseData = responseData['data'];
        }

        print('✅ Parsed order data: $responseData');

        return Order.fromJson(responseData);
      } else {
        throw Exception('Failed to create order: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('❌ Error in createOrderWithMode: $e');
      if (e is DioException) {
        print('❌ Response data: ${e.response?.data}');
        print('❌ Response status: ${e.response?.statusCode}');
        if (e.response?.data is Map) {
          final errorData = e.response?.data as Map;
          print('❌ Error message: ${errorData['message']}');
        }
      }
      rethrow;
    }
  }

  // ✅ Выполнение действия над заказом
  Future<void> executeAction(
      int orderId,
      OrderAction action,
      Map<String, dynamic> payload,
      ) async {
    final url = '/orders/$orderId/action';

    final requestData = {
      'action': action.value,
      'payload': payload,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📡 EXECUTE ACTION - URL: ${ApiConstants.baseUrl}$url');
    print('📡 EXECUTE ACTION - Action: ${action.value}');
    print('📡 EXECUTE ACTION - Full request: ${jsonEncode(requestData)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await _dio.post(
      '${ApiConstants.baseUrl}$url',
      data: requestData,
    );

    print('✅ Action executed, status: ${response.statusCode}');
    print('✅ Response data: ${response.data}');
  }


  // ✅ Получение открытых маркетплейс заказов
  Future<List<Order>> getOpenMarketplaceOrders() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/marketplace/orders/open',
      );

      print('✅ Open marketplace orders response: ${response.statusCode}');

      if (response.data is List) {
        final orders = (response.data as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        print('📊 Loaded ${orders.length} open orders');
        return orders;
      }
      return [];
    } catch (e) {
      print('❌ Error loading open marketplace orders: $e');
      return [];
    }
  }

  // ✅ Получение заказов клиента
  Future<List<Order>> getClientOrders() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.clientOrders}',
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => Order.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading client orders: $e');
      return [];
    }
  }

  // ✅ Получение заказов клинера
  Future<List<Order>> getCleanerOrders() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.cleanerOrders}',
      );

      if (response.data is List) {
        return (response.data as List)
            .map((e) => Order.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading cleaner orders: $e');
      return [];
    }
  }

  // ✅ Получение деталей заказа
  Future<Order> getOrderById(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/orders/$id',
    );
    return Order.fromJson(response.data);
  }
}