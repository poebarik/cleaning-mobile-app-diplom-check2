// lib/data/models/chat/message.dart
class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String? content;
  final List<String>? imageObjectNames;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    this.content,
    this.imageObjectNames,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Обработка imageObjectNames (может быть String или List)
    List<String>? imageObjectNames;
    if (json['imageObjectNames'] != null) {
      if (json['imageObjectNames'] is List) {
        imageObjectNames = List<String>.from(json['imageObjectNames']);
      } else if (json['imageObjectNames'] is String) {
        imageObjectNames = [json['imageObjectNames'] as String];
      }
    }

    return Message(
      id: json['id'] as int,
      chatId: json['chatId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      content: json['content'] as String?,
      imageObjectNames: imageObjectNames,
      imageUrl: json['imageUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'content': content,
      'imageObjectNames': imageObjectNames,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}