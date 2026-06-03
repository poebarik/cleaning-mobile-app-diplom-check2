import 'package:flutter/foundation.dart';

class ApiConstants {
  // HTTP Base URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    } else {
      return 'http://10.0.2.2:8080/api';
    }
  }

  // WebSocket Base URL
  static String get wsBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else {
      return 'http://10.0.2.2:8080';
    }
  }

  // ========== AUTH ==========
  static const String auth = '/auth';
  static const String register = '$auth/register';
  static const String login = '$auth/login';

  // ========== ORDERS (НОВЫЕ) ==========
  static const String createOrderWithMode = '/orders/create-with-mode';
  static const String orderAction = '/orders/{id}/action';
  static const String orders = '/orders';
  static const String clientOrders = '$orders/my/client';
  static const String cleanerOrders = '$orders/my/cleaner';
  static const String getOrderById = '$orders/{id}';

  // ========== MARKETPLACE (СТАРЫЕ - УДАЛЕНЫ) ==========
  static const String marketplace = '/marketplace';
  static const String marketplaceOrders = '$marketplace/orders';
  static const String openMarketplaceOrders = '$marketplace/orders/open';

  // ========== INVITATIONS ==========
  static const String invitations = '/invitations';
  static const String myInvitations = '$invitations/my';
  static const String cleanerInvitations = '$invitations/cleaner';
  static const String getInvitation = '$invitations/{id}';
  static const String getNegotiations = '$invitations/{id}/negotiations';

  // ❌ СТАРЫЕ INVITATION ENDPOINTS - УДАЛЕНЫ, теперь через action систему
  // static const String acceptInvitation = '/invitations/{id}/accept';
  // static const String declineInvitation = '/invitations/{id}/decline';
  // static const String counterOffer = '/invitations/{id}/counter-offer';
  // static const String acceptPrice = '/invitations/{id}/accept-price';
  // static const String rejectPrice = '/invitations/{id}/reject-price';
  // static const String clientCounterOffer = '/invitations/{id}/client-counter-offer';

  // ========== CHATS ==========
  static const String chats = '/chats';
  static const String chatMessages = '$chats/{id}/messages';
  static const String markChatRead = '$chats/{id}/read';

  // ========== FILES ==========
  static const String uploadFile = '/files/upload';
  static const String getFile = '/files/{objectName}';
  static const String deleteFile = '/files';

  // ========== MANAGER ==========
  static const String manager = '/manager';
  static const String pendingOrders = '$manager/orders/pending';
  static const String availableCleaners = '$manager/cleaners/available';
  static const String assignOrder = '$manager/orders/assign';
  static const String managerStats = '$manager/stats';
  static const String cleanersWorkload = '$manager/cleaners/workload';

  // ========== NOTIFICATIONS ==========
  static const String notifications = '/notifications';
  static const String unreadCount = '$notifications/unread/count';
  static const String markAsRead = '$notifications/read/{id}';
  static const String markAllAsRead = '$notifications/read-all';

  // ========== CLEANERS ==========
  static const String cleaners = '/cleaners';

  // ========== REVIEWS ==========
  static const String reviews = '/reviews';
  static const String cleanerReviews = '/reviews/cleaners/{id}';

  // ========== ADMIN ==========
  static const String admin = '/admin';
  static const String adminStats = '$admin/stats';
  static const String blockUser = '$admin/users/{id}/block';
  static const String unblockUser = '$admin/users/{id}/unblock';
}