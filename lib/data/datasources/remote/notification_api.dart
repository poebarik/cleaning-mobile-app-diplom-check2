import 'package:dio/dio.dart';
import '../../models/notification/notification.dart';
import '../../../core/constants/api_constants.dart';

class NotificationApi {
  final Dio _dio;

  NotificationApi(this._dio);

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.notifications}',
      );
      return (response.data as List)
          .map((e) => AppNotification.fromJson(e))
          .toList();
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.unreadCount}',
      );
      return response.data['count'] ?? 0;
    } catch (e) {
      print('❌ Error loading unread count: $e');
      return 0;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.notifications}/read/$notificationId',
      );
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.markAllAsRead}',
      );
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }
}