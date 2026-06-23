// lib/data/repositories/chat_repository.dart
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/chat/chat.dart';
import '../models/chat/message.dart';

class ChatRepository {
  final Dio _dio = DioClient.instance;

  // ✅ Получить все чаты
  Future<List<Chat>> getChats() async {
    try {
      final response = await _dio.get('/chats');
      final List data = response.data;
      return data.map((e) => Chat.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error loading chats: $e');
      if (e is DioException) {
        print('Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ✅ Создать новый чат
  Future<Chat> createChat({
    required int participantId,
    required String participantName,
  }) async {
    try {
      final response = await _dio.post(
        '/chats',
        data: {
          'participantId': participantId,
          'participantName': participantName,
        },
      );
      return Chat.fromJson(response.data);
    } catch (e) {
      print('❌ Error creating chat: $e');
      if (e is DioException) {
        print('Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ✅ Получить сообщения чата
  Future<List<Message>> getMessages(int chatId, {int page = 0, int size = 50}) async {
    try {
      final response = await _dio.get(
        '/chats/$chatId/messages',
        queryParameters: {
          'page': page,
          'size': size,
        },
      );
      final List data = response.data;
      return data.map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error loading messages: $e');
      if (e is DioException) {
        print('Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ✅ Отправить сообщение
  Future<void> sendMessage(int chatId, String content, {List<String>? imageObjectNames}) async {
    try {
      await _dio.post(
        '/chats/$chatId/messages',
        data: {
          'content': content,
          'imageObjectNames': imageObjectNames ?? [],
        },
      );
    } catch (e) {
      print('❌ Error sending message: $e');
      if (e is DioException) {
        print('Response: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // ✅ Отметить чат как прочитанный
  Future<void> markAsRead(int chatId) async {
    try {
      await _dio.post('/chats/$chatId/read');
    } catch (e) {
      print('❌ Error marking chat as read: $e');
    }
  }
}