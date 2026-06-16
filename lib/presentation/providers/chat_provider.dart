import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/chat_api.dart';
import '../../data/network/dio_client.dart';
import '../../data/network/websocket/websocket_service.dart';
import '../../data/models/chat/chat.dart';
import '../../data/models/chat/message.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});

class ChatNotifier extends StateNotifier<ChatState> {
  late final ChatApi _chatApi;
  late final WebSocketService _webSocketService;

  bool _isDisposed = false;

  Function(Message)? onMessageReceived;

  ChatNotifier() : super(const ChatStateInitial()) {
    _chatApi = ChatApi(DioClient.instance);
    _webSocketService = WebSocketService.instance;

    _webSocketService.onMessageReceived = (message) {
      if (_isDisposed) return;

      Future.microtask(() {
        if (!_isDisposed) {
          debugPrint('📨 WS: ChatNotifier received message ${message.id}');
          _addNewMessage(message);
          onMessageReceived?.call(message);
        }
      });
    };
  }

  Future<void> connectWebSocket() async {
    if (_isDisposed) return;
    await _webSocketService.connect();
  }

  void disconnectWebSocket() {
    if (_isDisposed) return;
    _webSocketService.disconnect();
  }

  void unsubscribeFromChat(int chatId) {
    if (_isDisposed) return;
    _webSocketService.unsubscribeFromChat(chatId);
  }

  void updateMessages(List<Message> messages) {
    if (_isDisposed) return;
    if (state is ChatStateMessagesLoaded) {
      final currentState = state as ChatStateMessagesLoaded;
      state = ChatStateMessagesLoaded(currentState.chatId, messages);
    }
  }

  Future<void> loadChats() async {
    if (_isDisposed) return;
    state = const ChatStateLoading();
    try {
      final chats = await _chatApi.getChats();
      if (!_isDisposed) {
        state = ChatStateChatsLoaded(chats);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = ChatStateError(e.toString());
      }
    }
  }

  Future<void> loadMessages(int chatId, {int page = 0, int size = 50}) async {
    if (_isDisposed) return;
    state = const ChatStateLoading();
    try {
      final messages = await _chatApi.getMessages(chatId, page: page, size: size);
      if (!_isDisposed) {
        debugPrint('📚 REST: Loaded ${messages.length} messages for chat $chatId');
        state = ChatStateMessagesLoaded(chatId, messages);

        _webSocketService.connect();
        _webSocketService.subscribeToChat(chatId);
      }
    } catch (e) {
      if (!_isDisposed) {
        state = ChatStateError(e.toString());
      }
    }
  }

  Future<void> sendMessage(int chatId, String content, {String? imageObjectName}) async {
    if (_isDisposed) return;
    await _webSocketService.connect();
    _webSocketService.sendMessage(chatId, content, imageObjectName: imageObjectName);
    debugPrint('📤 Sent message to chat $chatId: $content');
  }

  void _addNewMessage(Message message) {
    debugPrint('🔍 ADD MESSAGE id=${message.id} chat=${message.chatId}');

    if (state is ChatStateMessagesLoaded) {
      final currentState = state as ChatStateMessagesLoaded;
      if (currentState.chatId == message.chatId) {
        final exists = currentState.messages.any((m) => m.id == message.id);
        if (exists) {
          debugPrint('⏭️ WS: Message ${message.id} already exists, skipping');
          return;
        }

        final updatedMessages = [...currentState.messages, message];
        state = ChatStateMessagesLoaded(currentState.chatId, updatedMessages);
        debugPrint('✅ WS: Added message ${message.id}, total: ${updatedMessages.length}');
      }
    }
  }

  Future<void> markChatAsRead(int chatId) async {
    if (_isDisposed) return;
    await _webSocketService.connect();
    _webSocketService.markChatAsRead(chatId);
  }

  Future<void> sendMessageWithImages(int chatId, String content, List<String> imageObjectNames) async {
    if (content.isEmpty && imageObjectNames.isEmpty) return;

    // Отправляем сообщение с фото
    if (imageObjectNames.isNotEmpty) {
      // Если есть текст и фото, отправляем текст и прикрепляем фото
      for (final imageName in imageObjectNames) {
        await sendMessage(chatId, content.isEmpty ? '📷 Фото' : content, imageObjectName: imageName);
      }
    } else if (content.isNotEmpty) {
      await sendMessage(chatId, content);
    }

    // После отправки, обновляем сообщения
    if (state is ChatStateMessagesLoaded) {
      final currentState = state as ChatStateMessagesLoaded;
      await loadMessages(currentState.chatId);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _webSocketService.disconnect();
    super.dispose();
  }
}

// States
sealed class ChatState {
  const ChatState();
}

class ChatStateInitial extends ChatState {
  const ChatStateInitial();
}

class ChatStateLoading extends ChatState {
  const ChatStateLoading();
}

class ChatStateChatsLoaded extends ChatState {
  final List<Chat> chats;
  const ChatStateChatsLoaded(this.chats);
}

class ChatStateMessagesLoaded extends ChatState {
  final int chatId;
  final List<Message> messages;
  const ChatStateMessagesLoaded(this.chatId, this.messages);
}

class ChatStateError extends ChatState {
  final String error;
  const ChatStateError(this.error);
}

// Extension для удобной работы с состоянием
extension ChatStateExtension on ChatState {
  bool get isLoading => this is ChatStateLoading;
  bool get isChatsLoaded => this is ChatStateChatsLoaded;
  bool get isMessagesLoaded => this is ChatStateMessagesLoaded;

  List<Chat>? get chats {
    if (this is ChatStateChatsLoaded) {
      return (this as ChatStateChatsLoaded).chats;
    }
    return null;
  }

  (int chatId, List<Message> messages)? get messagesData {
    if (this is ChatStateMessagesLoaded) {
      final state = this as ChatStateMessagesLoaded;
      return (state.chatId, state.messages);
    }
    return null;
  }

  String? get error {
    if (this is ChatStateError) {
      return (this as ChatStateError).error;
    }
    return null;
  }
}