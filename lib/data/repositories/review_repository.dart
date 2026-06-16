// lib/data/repositories/review_repository.dart
import 'package:dio/dio.dart';
import '../models/review/review.dart';
import '../models/review/create_review_request.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class ReviewRepository {
  final Dio _dio = DioClient.instance;

  Future<void> createReview(CreateReviewRequest request) async {
    final data = request.toJson();
    print('📤 POST ${ApiConstants.baseUrl}/reviews');
    print('📤 Data: $data');

    await _dio.post(
      '${ApiConstants.baseUrl}/reviews',
      data: data,
    );
  }

  // ✅ ГЛАВНЫЙ МЕТОД - правильно парсит RatingStatsDTO
  Future<List<Review>> getUserReviews(int userId) async {
    try {
      print('📊 getUserReviews для userId: $userId');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/users/$userId/reviews',
      );

      print('📊 Статус: ${response.statusCode}');
      print('📊 Тип ответа: ${response.data.runtimeType}');

      final data = response.data;

      // ✅ Бэкенд возвращает RatingStatsDTO с полем recentReviews
      if (data is Map<String, dynamic>) {
        print('📊 Это Map. Ключи: ${data.keys}');

        if (data.containsKey('recentReviews')) {
          final reviewsList = data['recentReviews'] as List? ?? [];
          print('📊 Найдено ${reviewsList.length} отзывов в recentReviews');
          return reviewsList.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
        }

        // Если нет recentReviews, но есть другие поля
        print('📊 Нет поля recentReviews, возвращаем пустой список');
        return [];
      }

      // Если это список (для других эндпоинтов)
      if (data is List) {
        print('📊 Ответ - список из ${data.length} элементов');
        return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
      }

      print('📊 Неизвестный формат, возвращаем пустой список');
      return [];
    } catch (e) {
      print('❌ Ошибка получения отзывов: $e');
      return [];
    }
  }

  Future<List<Review>> getCleanerReviews(int cleanerId) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/reviews/cleaners/$cleanerId',
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
      return (data['recentReviews'] as List)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Review>> getClientReviews(int clientId) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/reviews/clients/$clientId',
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
      return (data['recentReviews'] as List)
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<Review>> getMyReviews() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/reviews/my',
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<Review>> getReviewsAboutMe() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/reviews/about-me',
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }
}