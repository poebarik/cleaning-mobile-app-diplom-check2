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
  bool _isDisposed = false;

  NotificationNotifier() : super(const NotificationStateInitial()) {
    _notificationApi = NotificationApi(DioClient.instance);
  }

  void startPolling() {
    if (_isDisposed) return;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isDisposed) {
        loadUnreadCount();
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> loadNotifications() async {
    if (_isDisposed) return;

    state = const NotificationStateLoading();
    try {
      final notifications = await _notificationApi.getNotifications();
      if (!_isDisposed) {
        state = NotificationStateLoaded(notifications);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = NotificationStateError(e.toString());
      }
    }
  }

  Future<void> loadUnreadCount() async {
    if (_isDisposed) return;

    try {
      final count = await _notificationApi.getUnreadCount();
      if (!_isDisposed) {
        if (state is NotificationStateLoaded) {
          final currentState = state as NotificationStateLoaded;
          state = NotificationStateLoaded(currentState.notifications, unreadCount: count);
        } else {
          state = NotificationStateUnreadCount(count);
        }
      }
    } catch (e) {
      // Silent fail for polling
    }
  }

  Future<void> markAsRead(int notificationId) async {
    if (_isDisposed) return;
    try {
      await _notificationApi.markAsRead(notificationId);
      await loadNotifications();
      await loadUnreadCount();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> markAllAsRead() async {
    if (_isDisposed) return;
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
    _isDisposed = true;
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
  bool get isLoaded => this is NotificationStateLoaded;
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
  String? get error {
    if (this is NotificationStateError) {
      return (this as NotificationStateError).error;
    }
    return null;
  }
}