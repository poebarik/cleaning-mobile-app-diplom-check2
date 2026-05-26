import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../../data/models/notification/notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationProvider.notifier).markAllAsRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Все уведомления отмечены как прочитанные')),
                );
              }
            },
            child: const Text('Все прочитано'),
          ),
        ],
      ),
      body: notificationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : notificationState.notifications == null ||
          notificationState.notifications!.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Нет уведомлений'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: notificationState.notifications!.length,
        itemBuilder: (context, index) {
          final notification = notificationState.notifications![index];
          return _buildNotificationTile(notification);
        },
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: notification.isRead ? null : Colors.blue.shade50,
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: Text(
          _formatDate(notification.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () async {
          if (!notification.isRead) {
            await ref.read(notificationProvider.notifier).markAsRead(notification.id);
          }
          if (notification.relatedId != null) {
            // Navigate to related content
          }
        },
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'ORDER_ASSIGNED':
        icon = Icons.assignment_turned_in;
        color = Colors.green;
        break;
      case 'RESPONSE_RECEIVED':
        icon = Icons.message;
        color = Colors.blue;
        break;
      case 'CLEANER_SELECTED':
        icon = Icons.person_add;
        color = Colors.orange;
        break;
      case 'STATUS_CHANGED':
        icon = Icons.update;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays} дн. назад';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} ч. назад';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} мин. назад';
    } else {
      return 'только что';
    }
  }
}