// lib/data/repositories/user_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/review/review.dart';
import '../models/user/user.dart';
import '../models/user/user_stats.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import 'file_repository.dart';

class UserRepository {
  final Dio _dio = DioClient.instance;
  final FileRepository _fileRepository = FileRepository();


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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('📤 Смена пароля');
      print('  - currentPassword: $currentPassword');
      print('  - newPassword: $newPassword');

      final response = await _dio.post(
        '/auth/change-password', // ✅ Правильный эндпоинт
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword, // Добавляем confirmPassword
        },
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Статус: ${response.statusCode}');
      print('📊 Ответ: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return;
        } else {
          throw Exception(data['message'] ?? 'Неизвестная ошибка');
        }
      } else if (response.statusCode == 400) {
        final data = response.data as Map<String, dynamic>?;
        final message = data?['message'] ?? 'Неверный запрос';
        throw Exception(message);
      } else {
        throw Exception('Ошибка смены пароля: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка смены пароля: $e');
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          final data = e.response?.data as Map<String, dynamic>?;
          throw Exception(data?['message'] ?? 'Неверный текущий пароль');
        }
        throw Exception('Ошибка сети: ${e.message}');
      }
      rethrow;
    }
  }

  // lib/data/repositories/user_repository.dart

  Future<String> uploadAvatar(dynamic file) async {
    try {
      print('📸 Начинаем загрузку аватарки...');
      print('📸 Тип файла: ${file.runtimeType}');
      print('📸 Платформа: ${kIsWeb ? "Web" : "Mobile"}');

      // 1️⃣ Сначала загружаем файл в MinIO
      final uploadResult = await _fileRepository.uploadFile(file, 'avatars');

      if (uploadResult == null) {
        throw Exception('Не удалось загрузить файл');
      }

      final objectName = uploadResult['objectName'] as String?;
      print('📸 objectName: $objectName');

      if (objectName == null) {
        throw Exception('Не удалось получить имя загруженного файла');
      }

      // 2️⃣ Обновляем аватар пользователя на сервере
      await _updateAvatarOnServer(objectName);

      // 3️⃣ Получаем URL для доступа к файлу
      final avatarUrl = _fileRepository.getFileUrl(objectName);
      print('✅ Аватар загружен: $avatarUrl');

      return avatarUrl;
    } catch (e) {
      print('❌ Ошибка загрузки аватарки: $e');
      rethrow;
    }
  }

  // ✅ Обновляем аватар пользователя на сервере
  Future<void> _updateAvatarOnServer(String avatarObjectName) async {
    try {
      print('📤 Обновление аватара на сервере: $avatarObjectName');

      final response = await _dio.post(
        '/users/avatar',  // ✅ Эндпоинт из вашего контроллера
        data: {
          'avatarObjectName': avatarObjectName,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📥 Статус обновления аватара: ${response.statusCode}');
      print('📥 Ответ: ${response.data}');

      if (response.statusCode != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final message = errorData?['message'] ?? 'Unknown error';
        throw Exception('Failed to update avatar: $message');
      }

      print('✅ Аватар обновлен на сервере');
    } catch (e) {
      print('❌ Ошибка обновления аватара на сервере: $e');
      rethrow;
    }
  }


  // ✅ Альтернативный метод с XFile (для веба)
  Future<String> uploadAvatarFromXFile(dynamic file) async {
    try {
      // Для веба file может быть XFile
      final result = await _fileRepository.uploadFiles([file], 'avatars');

      if (result.isNotEmpty) {
        final uploadedFile = result.first;
        final objectName = uploadedFile['objectName'] ?? uploadedFile['fileName'];

        if (objectName != null) {
          final avatarUrl = _fileRepository.getFileUrl(objectName);
          await _updateAvatarOnServer(objectName);
          return avatarUrl;
        }
      }

      throw Exception('Не удалось загрузить аватар');
    } catch (e) {
      print('❌ Ошибка загрузки аватарки: $e');
      rethrow;
    }
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

      if (data is Map<String, dynamic> && data.containsKey('recentReviews')) {
        final reviewsList = data['recentReviews'] as List? ?? [];
        print('📊 Найдено ${reviewsList.length} отзывов в recentReviews');
        return reviewsList.map((e) => Review.fromJson(e)).toList();
      }

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
  // lib/data/repositories/user_repository.dart

  // lib/data/repositories/user_repository.dart

  Future<int?> getUserIdByClientId(int clientId) async {
    try {
      print('🔍 Получение userId для clientId: $clientId');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}/users/$clientId',
        options: Options(
          validateStatus: (status) => status! < 500,
        ),
      );

      print('📊 Статус ответа: ${response.statusCode}');
      print('📊 Данные: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // ✅ Парсим данные
        final data = response.data as Map<String, dynamic>;

        // ✅ Пробуем получить id разными способами
        int? userId = data['id'] as int?;

        // Если id нет, пробуем получить из fullName или email (но это не надежно)
        if (userId == null || userId == 0) {
          // Пробуем найти id в других полях
          userId = data['userId'] as int?;
        }

        if (userId != null && userId > 0) {
          print('✅ Найден userId: $userId для clientId: $clientId');
          return userId;
        }

        print('⚠️ userId не найден в ответе: $data');
        // ✅ ВОЗВРАЩАЕМ САМ clientId, если это ID пользователя
        return clientId;
      }

      print('⚠️ Не удалось найти пользователя с clientId: $clientId');
      return null;
    } catch (e) {
      print('❌ Ошибка получения userId для clientId $clientId: $e');
      // ✅ В случае ошибки возвращаем clientId (это может быть тот же ID)
      return clientId;
    }
  }

}