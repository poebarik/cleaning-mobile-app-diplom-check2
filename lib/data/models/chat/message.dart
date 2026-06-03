class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String senderName;
  final String? content;
  final String? imageObjectName;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.content,
    this.imageObjectName,
    this.imageUrl,
    this.isRead = false,  // ✅ Значение по умолчанию
    required this.createdAt,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      chatId: json['chatId'] as int,
      senderId: json['senderId'] as int,
      senderName: json['senderName'] as String,
      content: json['content'] as String?,
      imageObjectName: json['imageObjectName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      // ✅ isRead может отсутствовать в WebSocket сообщении
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'imageObjectName': imageObjectName,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
    };
  }
}