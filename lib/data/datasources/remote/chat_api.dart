import 'package:dio/dio.dart';
import '../../models/chat/chat.dart';
import '../../models/chat/message.dart';
import '../../../core/constants/api_constants.dart';

class ChatApi {
  final Dio _dio;

  ChatApi(this._dio);

  // Только для получения списка чатов
  Future<List<Chat>> getChats() async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.chats}',
    );
    return (response.data as List)
        .map((e) => Chat.fromJson(e))
        .toList();
  }

  // ТОЛЬКО для истории сообщений (REST)
  Future<List<Message>> getMessages(int chatId, {int page = 0, int size = 50}) async {
    final response = await _dio.get(
      '${ApiConstants.baseUrl}${ApiConstants.chats}/$chatId/messages',
      queryParameters: {
        'page': page,
        'size': size,
      },
    );

    // Поддержка пагинированного ответа
    if (response.data is Map && response.data['content'] != null) {
      return (response.data['content'] as List)
          .map((e) => Message.fromJson(e))
          .toList();
    }

    return (response.data as List)
        .map((e) => Message.fromJson(e))
        .toList();
  }

// ❌ УДАЛЕНО: sendMessage - теперь только через WebSocket
}