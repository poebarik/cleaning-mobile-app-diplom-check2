import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

class ManagerApi {
  final Dio _dio;

  ManagerApi(this._dio);

  Future<List<Map<String, dynamic>>> getPendingOrders() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.pendingOrders}',
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getAvailableCleaners() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.availableCleaners}',
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> assignCleanerToOrder(int orderId, int cleanerId) async {
    await _dio.post(
      '${ApiConstants.baseUrl}${ApiConstants.assignOrder}',
      data: {
        'orderId': orderId,
        'cleanerId': cleanerId,
      },
    );
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.managerStats}',
    );
    return response.data;
  }
}