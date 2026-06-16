// lib/data/models/chat/chat.dart
import 'message.dart';

class Chat {
  final int id;
  final int clientId;
  final String clientName;
  final int cleanerId;
  final String cleanerName;
  final String? clientAvatarUrl;
  final String? cleanerAvatarUrl;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.cleanerId,
    required this.cleanerName,
    this.clientAvatarUrl,
    this.cleanerAvatarUrl,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      cleanerId: json['cleanerId'] as int,
      cleanerName: json['cleanerName'] as String,
      clientAvatarUrl: json['clientAvatarUrl'] as String?,
      cleanerAvatarUrl: json['cleanerAvatarUrl'] as String?,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'clientAvatarUrl': clientAvatarUrl,
      'cleanerAvatarUrl': cleanerAvatarUrl,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}