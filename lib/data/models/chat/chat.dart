import 'message.dart';

class Chat {
  final int id;
  final int clientId;
  final String clientName;      // ✅ Имя клиента
  final int cleanerId;
  final String cleanerName;     // ✅ Имя клинера
  final int? orderId;
  final int? invitationId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final Message? lastMessage;

  Chat({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.cleanerId,
    required this.cleanerName,
    this.orderId,
    this.invitationId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.lastMessage,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      cleanerId: json['cleanerId'] as int,
      cleanerName: json['cleanerName'] as String,
      orderId: json['orderId'] as int?,
      invitationId: json['invitationId'] as int?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
    );
  }
}