// lib/data/repositories/response_repository.dart
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/order/order_response.dart';

class ResponseRepository {
  final Dio _dio = DioClient.instance;

  // Получить отклики на заказ
  Future<List<OrderResponse>> getResponsesForOrder(int orderId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/orders/$orderId',
      );

      // Бэкенд возвращает поле responses в деталях заказа
      final responses = response.data['responses'] as List? ?? [];
      return responses.map((e) => OrderResponse.fromJson(e)).toList();
    } catch (e) {
      print('Error loading responses: $e');
      return [];
    }
  }

  // Выбрать клинера
  Future<void> selectCleaner(int orderId, int responseId) async {
    await _dio.post(
      '${ApiConstants.baseUrl}/orders/$orderId/action',
      data: {
        'action': 'SELECT_CLEANER',
        'payload': {
          'responseId': responseId,
        },
      },
    );
  }
}