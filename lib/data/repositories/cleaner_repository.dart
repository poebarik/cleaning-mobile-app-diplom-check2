// lib/data/repositories/cleaner_repository.dart
import 'package:dio/dio.dart';
import '../models/cleaner/cleaner.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class CleanerRepository {
  final Dio _dio = DioClient.instance;

  Future<List<Cleaner>> getCleaners({bool availableOnly = false}) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}/cleaners',
        queryParameters: availableOnly ? {'availableOnly': true} : null,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Cleaner.fromJson(json)).toList();
    } catch (e) {
      print('❌ Ошибка загрузки клинеров: $e');
      return [];
    }
  }

  Future<Cleaner> getCleanerById(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/cleaners/$id',
    );
    return Cleaner.fromJson(response.data);
  }

  Future<Map<String, dynamic>> getCleanerStats(int id) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/cleaners/$id/stats',
    );
    return response.data;
  }
  Future<int?> getUserIdByCleanerId(int cleanerId) async {
    try {
      final cleaner = await getCleanerById(cleanerId);
      final userId = cleaner.userId;
      print('✅ Найден userId: $userId для cleanerId: $cleanerId');
      return userId;
    } catch (e) {
      print('❌ Ошибка получения userId для cleanerId $cleanerId: $e');
      return null;
    }
  }





}
