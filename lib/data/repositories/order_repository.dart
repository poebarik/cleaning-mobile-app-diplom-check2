// lib/data/repositories/order_repository.dart

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
      print('📤 SENDING ORDER REQUEST:');
      print('  - fulfillmentType: ${request.fulfillmentType}');
      print('  - cleanerId: ${request.cleanerId}');
      print('  - budget: ${request.budget}');

      final response = await _dio.post(
        ApiConstants.createOrderWithMode,
        data: request.toJson(),
      );

      print('📥 ORDER RESPONSE:');
      print('  - status: ${response.statusCode}');
      print('  - data: ${response.data}');

      return Order.fromJson(response.data);
    } catch (e) {
      print('❌ Error creating order: $e');
      if (e is DioException) {
        print('Response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ✅ Получение открытых маркетплейс заказов
  Future<List<Order>> getOpenMarketplaceOrders() async {
    try {
      final response = await _dio.get(
        ApiConstants.openMarketplaceOrders,
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

  // ✅ Получение заказов текущего клиента
  Future<List<Order>> getClientOrders() async {
    try {
      final response = await _dio.get(
        ApiConstants.clientOrders,
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

  // ✅ Получение заказов текущего клинера
  Future<List<Order>> getCleanerOrders() async {
    try {
      final response = await _dio.get(
        ApiConstants.cleanerOrders,
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

  // ✅ Получение заказов по ID клиента (для просмотра профиля)
  Future<List<Order>> getClientOrdersById(int clientId) async {
    try {
      final response = await _dio.get('/orders/client/$clientId');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Order.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading client orders by id: $e');
      return [];
    }
  }

  // ✅ Получение заказов по ID клинера (для просмотра профиля)
  // lib/data/repositories/order_repository.dart

  Future<List<Order>> getCleanerOrdersById(int cleanerId) async {
    try {
      final response = await _dio.get('/orders/cleaner/$cleanerId');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Order.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading cleaner orders by id: $e');
      return [];
    }
  }

  // ✅ Получение завершенных заказов клиента
  Future<List<Order>> getCompletedClientOrders(int clientId) async {
    try {
      final response = await _dio.get('/orders/client/$clientId/completed');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Order.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading completed client orders: $e');
      return [];
    }
  }

  // ✅ Получение завершенных заказов клинера
  Future<List<Order>> getCompletedCleanerOrders(int cleanerId) async {
    try {
      final response = await _dio.get('/orders/cleaner/$cleanerId/completed');
      if (response.data is List) {
        return (response.data as List)
            .map((e) => Order.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error loading completed cleaner orders: $e');
      return [];
    }
  }

  // ✅ Получение деталей заказа
  Future<Order> getOrderById(int id) async {
    final response = await _dio.get('/orders/$id');
    return Order.fromJson(response.data);
  }

  // ✅ Выполнение действия над заказом
  Future<void> executeAction(int orderId, OrderAction action, Map<String, dynamic> payload) async {
    try {
      await _dio.post(
        '/orders/$orderId/action',
        data: {
          'action': action.value,
          'payload': payload,
        },
      );
    } catch (e) {
      print('❌ Ошибка выполнения действия: $e');
      rethrow;
    }
  }

  // ✅ Отправка приглашения
  Future<void> sendInvitation({
    required int orderId,
    required int cleanerId,
    required double proposedPrice,
    required String message,
  }) async {
    try {
      await _dio.post(
        '/orders/$orderId/invitations',
        data: {
          'cleanerId': cleanerId,
          'proposedPrice': proposedPrice,
          'message': message,
        },
      );
    } catch (e) {
      print('❌ Ошибка отправки приглашения: $e');
      rethrow;
    }
  }

  // ✅ Получить userId по cleanerId (используем getCleanerOrdersById)
  Future<int?> getUserIdByCleanerId(int cleanerId) async {
    try {
      final orders = await getCleanerOrdersById(cleanerId);
      if (orders.isNotEmpty) {
        // Из первого заказа берем userId
        final userId = orders.first.userId;
        print('✅ Найден userId: $userId для cleanerId: $cleanerId');
        return userId;
      }
      print('⚠️ Заказы не найдены для cleanerId: $cleanerId');
      return null;
    } catch (e) {
      print('❌ Ошибка получения userId: $e');
      return null;
    }
  }
}