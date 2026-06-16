import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../notifications/notifications_screen.dart';

class NotificationBadgeWidget extends ConsumerStatefulWidget {
  const NotificationBadgeWidget({super.key});

  @override
  ConsumerState<NotificationBadgeWidget> createState() => _NotificationBadgeWidgetState();
}

class _NotificationBadgeWidgetState extends ConsumerState<NotificationBadgeWidget> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Откладываем загрузку до следующего фрейма
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        // Используем WidgetsBinding.instance.addPostFrameCallback вместо прямого вызова
        ref.read(notificationProvider.notifier).loadUnreadCount();
        ref.read(notificationProvider.notifier).startPolling();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Отключаем polling при уничтожении виджета
    ref.read(notificationProvider.notifier).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Используем watch только если виджет не уничтожен
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            if (mounted && !_isDisposed) {
              ref.read(notificationProvider.notifier).loadUnreadCount();
            }
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}