import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/notification_api.dart';
import '../../data/network/dio_client.dart';
import '../../data/models/notification/notification.dart';
import 'dart:async';

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

class NotificationNotifier extends StateNotifier<NotificationState> {
  late final NotificationApi _notificationApi;
  Timer? _pollingTimer;

  NotificationNotifier() : super(const NotificationStateInitial()) {
    _notificationApi = NotificationApi(DioClient.instance);
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      loadUnreadCount();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> loadNotifications() async {
    state = const NotificationStateLoading();
    try {
      final notifications = await _notificationApi.getNotifications();
      state = NotificationStateLoaded(notifications);
    } catch (e) {
      state = NotificationStateError(e.toString());
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _notificationApi.getUnreadCount();
      if (state is NotificationStateLoaded) {
        final currentState = state as NotificationStateLoaded;
        state = NotificationStateLoaded(currentState.notifications, unreadCount: count);
      } else {
        state = NotificationStateUnreadCount(count);
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationApi.markAsRead(notificationId);
      await loadNotifications();
      await loadUnreadCount();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationApi.markAllAsRead();
      await loadNotifications();
      await loadUnreadCount();
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

// States
sealed class NotificationState {
  const NotificationState();
}

class NotificationStateInitial extends NotificationState {
  const NotificationStateInitial();
}

class NotificationStateLoading extends NotificationState {
  const NotificationStateLoading();
}

class NotificationStateLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  const NotificationStateLoaded(this.notifications, {this.unreadCount = 0});
}

class NotificationStateUnreadCount extends NotificationState {
  final int count;
  const NotificationStateUnreadCount(this.count);
}

class NotificationStateError extends NotificationState {
  final String error;
  const NotificationStateError(this.error);
}

extension NotificationStateExtension on NotificationState {
  bool get isLoading => this is NotificationStateLoading;
  List<AppNotification>? get notifications {
    if (this is NotificationStateLoaded) {
      return (this as NotificationStateLoaded).notifications;
    }
    return null;
  }
  int get unreadCount {
    if (this is NotificationStateLoaded) {
      return (this as NotificationStateLoaded).unreadCount;
    }
    if (this is NotificationStateUnreadCount) {
      return (this as NotificationStateUnreadCount).count;
    }
    return 0;
  }
}