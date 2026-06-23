// lib/data/repositories/review_repository.dart
import 'package:dio/dio.dart';
import '../models/review/review.dart';
import '../models/review/create_review_request.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class ReviewRepository {
  final Dio _dio = DioClient.instance;

  Future<Review> createReview(CreateReviewRequest request) async {
    try {
      print('📤 Sending review:');
      print('  - orderId: ${request.orderId}');
      print('  - targetUserId: ${request.targetUserId}');
      print('  - rating: ${request.rating}');
      print('  - reviewType: ${request.reviewType}');

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/reviews',
        data: request.toJson(),
      );

      return Review.fromJson(response.data);
    } catch (e) {
      print('❌ Error creating review: $e');
      rethrow;
    }
  }

  // ✅ Исправленный метод - используем правильный путь и обрабатываем ошибки
  Future<List<Review>> getUserReviews(int userId) async {
    try {
      print('📊 getUserReviews для userId: $userId');

      final response = await _dio.get(
        '/reviews/users/$userId',
        options: Options(
          validateStatus: (status) => status! < 500, // Не выбрасываем исключение для 4xx
        ),
      );

      print('📊 Статус: ${response.statusCode}');

      // Обрабатываем 404 - эндпоинт не найден
      if (response.statusCode == 404) {
        print('⚠️ Эндпоинт /reviews/users/$userId не найден, пробуем альтернативный');
        return await _getUserReviewsAlternative(userId);
      }

      // Обрабатываем другие ошибки
      if (response.statusCode != 200) {
        print('❌ Ошибка: ${response.statusCode}');
        return [];
      }

      print('📊 Тип ответа: ${response.data.runtimeType}');

      final data = response.data;

      // Бэкенд возвращает RatingStatsDTO с полем recentReviews
      if (data is Map<String, dynamic>) {
        print('📊 Это Map. Ключи: ${data.keys}');

        if (data.containsKey('recentReviews')) {
          final reviewsList = data['recentReviews'] as List? ?? [];
          print('📊 Найдено ${reviewsList.length} отзывов в recentReviews');
          return reviewsList.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
        }

        if (data.containsKey('reviews')) {
          final reviewsList = data['reviews'] as List? ?? [];
          print('📊 Найдено ${reviewsList.length} отзывов в reviews');
          return reviewsList.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
        }

        print('📊 Нет поля recentReviews или reviews, возвращаем пустой список');
        return [];
      }

      // Если это список
      if (data is List) {
        print('📊 Ответ - список из ${data.length} элементов');
        return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
      }

      print('📊 Неизвестный формат, возвращаем пустой список');
      return [];
    } catch (e) {
      print('❌ Ошибка получения отзывов: $e');
      if (e is DioException) {
        print('Response: ${e.response?.data}');
        // Если ошибка 404, пробуем альтернативный метод
        if (e.response?.statusCode == 404) {
          return await _getUserReviewsAlternative(userId);
        }
      }
      return [];
    }
  }

  // ✅ Альтернативный метод получения отзывов (если основной эндпоинт не работает)
  Future<List<Review>> _getUserReviewsAlternative(int userId) async {
    try {
      print('🔄 Пробуем альтернативный метод получения отзывов для userId: $userId');

      // Пробуем получить отзывы через эндпоинт клиента
      try {
        final response = await _dio.get(
          '/reviews/clients/$userId',
          options: Options(
            validateStatus: (status) => status! < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
            return (data['recentReviews'] as List)
                .map((e) => Review.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (e) {
        print('❌ Ошибка получения отзывов через клиент: $e');
      }

      // Пробуем получить отзывы через эндпоинт клинера
      try {
        final response = await _dio.get(
          '/reviews/cleaners/$userId',
          options: Options(
            validateStatus: (status) => status! < 500,
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
            return (data['recentReviews'] as List)
                .map((e) => Review.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (e) {
        print('❌ Ошибка получения отзывов через клинера: $e');
      }

      print('⚠️ Не удалось получить отзывы альтернативными методами');
      return [];
    } catch (e) {
      print('❌ Ошибка в альтернативном методе: $e');
      return [];
    }
  }

  Future<List<Review>> getCleanerReviews(int cleanerId) async {
    try {
      final response = await _dio.get('/reviews/cleaners/$cleanerId');
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
        return (data['recentReviews'] as List)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка получения отзывов о клинере: $e');
      return [];
    }
  }

  Future<List<Review>> getClientReviews(int clientId) async {
    try {
      final response = await _dio.get('/reviews/clients/$clientId');
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
        return (data['recentReviews'] as List)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка получения отзывов о клиенте: $e');
      return [];
    }
  }

  Future<List<Review>> getMyReviews() async {
    try {
      final response = await _dio.get('/reviews/my');
      final data = response.data;
      if (data is List) {
        return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка получения моих отзывов: $e');
      return [];
    }
  }

  Future<List<Review>> getReviewsAboutMe() async {
    try {
      final response = await _dio.get('/reviews/about-me');
      final data = response.data;
      if (data is List) {
        return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Ошибка получения отзывов обо мне: $e');
      return [];
    }
  }

  // ✅ Получение среднего рейтинга пользователя с альтернативными методами
  Future<double?> getUserAverageRating(int userId) async {
    try {
      print('📊 Получение среднего рейтинга для userId: $userId');

      final response = await _dio.get(
        '/reviews/users/$userId/rating',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final rating = data['averageRating']?.toDouble();
        print('✅ Рейтинг получен: $rating');
        return rating;
      } else if (response.statusCode == 404) {
        print('⚠️ Эндпоинт рейтинга не найден (404), вычисляем из отзывов');
        return await _getAverageRatingFromReviews(userId);
      } else {
        print('⚠️ Не удалось получить рейтинг: ${response.statusCode}');
        return await _getAverageRatingFromReviews(userId);
      }
    } catch (e) {
      print('❌ Ошибка получения рейтинга: $e');
      try {
        return await _getAverageRatingFromReviews(userId);
      } catch (e) {
        return null;
      }
    }
  }

  // ✅ Вычисление среднего рейтинга из списка отзывов
  Future<double?> _getAverageRatingFromReviews(int userId) async {
    try {
      print('🔄 Вычисляем средний рейтинг из отзывов для userId: $userId');
      final reviews = await getUserReviews(userId);

      if (reviews.isEmpty) {
        print('⚠️ Нет отзывов для вычисления рейтинга');
        return null;
      }

      final sum = reviews.fold<double>(0, (sum, review) => sum + review.rating);
      final average = sum / reviews.length;
      print('✅ Вычислен средний рейтинг: $average из ${reviews.length} отзывов');
      return average;
    } catch (e) {
      print('❌ Ошибка вычисления рейтинга: $e');
      return null;
    }
  }
}