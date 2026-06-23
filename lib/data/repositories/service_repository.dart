// lib/data/repositories/service_repository.dart
import 'package:dio/dio.dart';
import '../models/service/popular_service.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class ServiceRepository {
  final Dio _dio = DioClient.instance;

  Future<List<PopularService>> getPopularServices() async {
    try {
      final response = await _dio.get(
        '/services/popular',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((json) => PopularService.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки популярных сервисов: $e');
      return [];
    }
  }

  Future<List<PopularService>> searchServices(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get(
        '/services/search',
        queryParameters: {'query': query},
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((json) => PopularService.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка поиска сервисов: $e');
      return [];
    }
  }

  // ✅ Получить все сервисы с фильтрацией
  Future<List<PopularService>> getAllServices({
    String? category,
    String? cleaningType,
    double? minPrice,
    double? maxPrice,
    bool? isPopular,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (cleaningType != null && cleaningType.isNotEmpty) queryParams['cleaningType'] = cleaningType;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (isPopular != null) queryParams['isPopular'] = isPopular;

      print('📤 GET /services/all with params: $queryParams');

      final response = await _dio.get(
        '/services/all',
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        print('✅ Получено ${data.length} сервисов');
        return data.map((json) => PopularService.fromJson(json)).toList();
      }
      print('⚠️ Ошибка: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки сервисов: $e');
      return [];
    }
  }

  Future<List<PopularService>> getServicesByCategory(String category) async {
    try {
      final response = await _dio.get(
        '/services/category/$category',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((json) => PopularService.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки сервисов по категории: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get(
        '/services/categories',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки категорий: $e');
      return [];
    }
  }

  Future<List<String>> getCleaningTypes() async {
    try {
      final response = await _dio.get(
        '/services/cleaning-types',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data is List ? response.data : [];
        return data.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка загрузки типов уборки: $e');
      return [];
    }
  }
}