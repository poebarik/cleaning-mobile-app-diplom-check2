import 'package:dio/dio.dart';
import '../../models/notification/notification.dart';
import '../../../core/constants/api_constants.dart';

class NotificationApi {
  final Dio _dio;

  NotificationApi(this._dio);

  Future<List<AppNotification>> getNotifications() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.notifications}',
    );
    return (response.data as List)
        .map((e) => AppNotification.fromJson(e))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.unreadCount}',
    );
    return response.data['count'] ?? 0;
  }

  Future<void> markAsRead(int notificationId) async {
    await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.notifications}/read/$notificationId',
    );
  }

  Future<void> markAllAsRead() async {
    await _dio.patch(
      '${ApiConstants.baseUrl}${ApiConstants.markAllAsRead}',
    );
  }
}