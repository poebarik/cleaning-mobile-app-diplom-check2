import 'package:flutter/foundation.dart';
class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else {
      return 'http://10.0.2.2:8080/api';
    }
  }

  // Auth endpoints
  static const String auth = '/auth';
  static const String register = '$auth/register';
  static const String login = '$auth/login';

  // Order endpoints - ОБНОВЛЕННЫЕ
  static const String orders = '/orders';
  static const String clientOrders = '$orders/client';
  static const String cleanerOrders = '$orders/cleaner'; // Вместо /cleaner/assigned
  static const String updateOrderStatus = '$orders/{id}/status';

  // Marketplace endpoints
  static const String marketplace = '/marketplace';
  static const String marketplaceOrders = '$marketplace/orders';
  static const String openOrders = '$marketplace/orders/open';
  static const String respondToOrder = '$marketplace/orders/{id}/respond';
  static const String selectCleaner = '$marketplace/orders/{id}/select-cleaner';

  // Cleaner endpoints
  static const String cleaners = '/cleaners';

  // Review endpoints
  static const String reviews = '/reviews';
  static const String cleanerReviews = '/reviews/cleaners/{id}';

  // Admin endpoints
  static const String admin = '/admin';
  static const String stats = '$admin/stats';
  static const String blockUser = '$admin/users/{id}/block';
  static const String unblockUser = '$admin/users/{id}/unblock';

  // Manager endpoints
  static const String manager = '/manager';
  static const String pendingOrders = '$manager/orders/pending';
  static const String availableCleaners = '$manager/cleaners/available';
  static const String assignOrder = '$manager/orders/assign';
  static const String managerStats = '$manager/stats';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String unreadCount = '$notifications/unread/count';
  static const String markAsRead = '$notifications/read/{id}';
  static const String markAllAsRead = '$notifications/read-all';
}