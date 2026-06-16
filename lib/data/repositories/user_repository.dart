// lib/data/repositories/user_repository.dart
import 'package:cleaning_mobile_application/data/repositories/review_repository.dart';
import 'package:dio/dio.dart';
import '../models/review/review.dart';
import '../models/user/user.dart';
import '../models/user/user_stats.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';

class UserRepository {
  final Dio _dio = DioClient.instance;

  Future<User> getCurrentUser() async {
    final response = await _dio.get('${ApiConstants.baseUrl}/users/me');
    return User.fromJson(response.data);
  }

  Future<User> getUserById(int userId) async {
    final response = await _dio.get('${ApiConstants.baseUrl}/users/$userId');
    return User.fromJson(response.data);
  }

  Future<User> updateProfile({
    String? name,
    String? phone,
    String? description,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (description != null) data['description'] = description;

    final response = await _dio.put(
      '${ApiConstants.baseUrl}/users/me',
      data: data,
    );
    return User.fromJson(response.data);
  }

  Future<void> updateAvatar(String avatarObjectName) async {
    await _dio.post(
      '${ApiConstants.baseUrl}/users/avatar',
      data: {'avatarObjectName': avatarObjectName},
    );
  }

  Future<String?> getAvatar() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}/users/avatar');
      return response.data['url'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteAvatar() async {
    await _dio.delete('${ApiConstants.baseUrl}/users/avatar');
  }

  Future<List<Review>> getReviewsAboutMe({int page = 0, int size = 10}) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/reviews/about-me',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    final reviewsList = data['recentReviews'] as List? ??
        (data is List ? data : []);
    return reviewsList.map((e) => Review.fromJson(e)).toList();
  }

  Future<List<Review>> getMyReviews({int page = 0, int size = 10}) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}/reviews/my',
      queryParameters: {'page': page, 'size': size},
    );
    return (response.data as List).map((e) => Review.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getMyStats() async {
    final response = await _dio.get('${ApiConstants.baseUrl}/users/me/profile');
    return response.data;
  }

  Future<void> deleteAccount() async {
    await _dio.delete('${ApiConstants.baseUrl}/users/me');
  }

  Future<User> getUserProfile(int userId) async {
    final response = await _dio.get('${ApiConstants.baseUrl}/users/profile/$userId');
    return User.fromJson(response.data);
  }

  Future<User> getMyProfile() async {
    final response = await _dio.get('${ApiConstants.baseUrl}/users/me');
    return User.fromJson(response.data);
  }

  // ✅ ИСПРАВЛЕННЫЙ МЕТОД
  Future<List<Review>> getUserReviews(int userId) async {
    try {
      print('📊 getUserReviews для userId: $userId');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/users/$userId/reviews',
      );

      print('📊 Статус: ${response.statusCode}');
      print('📊 ТИП ДАННЫХ: ${response.data.runtimeType}');
      print('📊 СОДЕРЖИМОЕ: ${response.data}');

      final dynamic data = response.data;

      // ✅ Бэкенд возвращает RatingStatsDTO с полем recentReviews
      if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
        final reviewsList = data['recentReviews'] as List? ?? [];
        print('📊 Найдено ${reviewsList.length} отзывов в recentReviews');
        return reviewsList.map((e) => Review.fromJson(e)).toList();
      }

      // Если это список (для других эндпоинтов)
      if (data is List) {
        print('📊 Ответ - список из ${data.length} элементов');
        return data.map((e) => Review.fromJson(e)).toList();
      }

      print('📊 Неизвестный формат, возвращаем пустой список');
      return [];
    } catch (e) {
      print('❌ Ошибка: $e');
      return [];
    }
  }

  Future<UserStats> getUserStats(int userId) async {
    final response = await _dio.get('${ApiConstants.baseUrl}/users/$userId/stats');
    return UserStats.fromJson(response.data);
  }
}