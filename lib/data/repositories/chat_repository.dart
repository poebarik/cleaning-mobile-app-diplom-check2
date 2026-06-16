// lib/data/repositories/chat_repository.dart
import 'package:dio/dio.dart';
import '../network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/chat/chat.dart';

class ChatRepository {
  final Dio _dio = DioClient.instance;

  Future<Chat> createChat({
    required int participantId,
    required String participantName,
  }) async {
    final response = await _dio.post(
      '${ApiConstants.baseUrl}/chats',
      data: {
        'participantId': participantId,
        'participantName': participantName,
      },
    );
    return Chat.fromJson(response.data);
  }
}