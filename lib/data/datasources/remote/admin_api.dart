import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

class AdminApi {
  final Dio _dio;

  AdminApi(this._dio);

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.stats}',
    );
    return response.data;
  }

  Future<void> blockUser(int id) async {
    await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.admin}/users/$id/block',
    );
  }

  Future<void> unblockUser(int id) async {
    await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.admin}/users/$id/unblock',
    );
  }
}