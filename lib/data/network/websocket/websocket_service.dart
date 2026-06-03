import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/chat/message.dart';

class WebSocketService {
  static WebSocketService? _instance;
  StompClient? _stompClient;
  String? _token;
  bool _isConnected = false;
  Completer<void>? _connectionCompleter;

  // ✅ Хранилище активных подписок для предотвращения дублей
  final Set<String> _activeSubscriptions = {};

  // ✅ Хранилище объектов отписки
  final Map<String, void Function()> _subscriptions = {};

  // Callbacks
  Function(Message)? onMessageReceived;
  Function(int, int)? onMessagesRead;

  WebSocketService._internal();

  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  Future<void> connect() async {
    if (_isConnected) {
      debugPrint('✅ WebSocket already connected');
      return;
    }

    final storage = const FlutterSecureStorage();
    _token = await storage.read(key: 'access_token');

    if (_token == null) {
      debugPrint('❌ WebSocket: No token available');
      return;
    }

    final wsUrl = ApiConstants.wsBaseUrl;
    debugPrint('🔌 WebSocket connecting to: $wsUrl/ws/chat');

    _connectionCompleter = Completer<void>();

    _stompClient = StompClient(
      config: StompConfig.sockJS(
        url: '$wsUrl/ws/chat',
        stompConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $_token',
        },
        onConnect: (frame) {
          _isConnected = true;
          _connectionCompleter?.complete();
          debugPrint('✅ WebSocket connected successfully');
        },
        onWebSocketError: (error) {
          _isConnected = false;
          _connectionCompleter?.completeError(error);
          debugPrint('❌ WebSocket error: $error');
        },
        onStompError: (frame) {
          debugPrint('❌ STOMP error: ${frame.body}');
        },
        onDisconnect: (frame) {
          _isConnected = false;
          _activeSubscriptions.clear();
          _subscriptions.clear();
          debugPrint('🔌 WebSocket disconnected');
        },
      ),
    );

    _stompClient!.activate();

    // ✅ Ждем фактического подключения
    await _connectionCompleter!.future;
  }

  void subscribeToChat(int chatId) {
    final subscriptionId = 'chat_$chatId';

    // ✅ Если уже подписаны - не подписываемся снова
    if (_activeSubscriptions.contains(subscriptionId)) {
      debugPrint('📡 Already subscribed to chat: $chatId, skipping');
      return;
    }

    if (!_isConnected) {
      debugPrint('⚠️ WebSocket not connected, will subscribe after connection');
      connect().then((_) {
        if (_isConnected && _stompClient != null) {
          _doSubscribe(chatId, subscriptionId);
        }
      });
      return;
    }

    _doSubscribe(chatId, subscriptionId);
  }

  void _doSubscribe(int chatId, String subscriptionId) {
    debugPrint('📡 Subscribing to chat: $chatId');

    final unsubscribe = _stompClient!.subscribe(
      destination: '/topic/chat/$chatId',
      headers: {
        'Authorization': 'Bearer $_token',
      },
      callback: (frame) {
        try {
          if (frame.body == null || frame.body!.isEmpty) return;

          final data = jsonDecode(frame.body!);
          debugPrint('📨 Message received: ${data['id']}');

          final message = Message.fromJson(Map<String, dynamic>.from(data));

          onMessageReceived?.call(message);
        } catch (e) {
          debugPrint('❌ Error parsing message: $e');
        }
      },
    );

    // ✅ Сохраняем функцию отписки
    _subscriptions[subscriptionId] = unsubscribe;
    _activeSubscriptions.add(subscriptionId);
  }

  void unsubscribeFromChat(int chatId) {
    final subscriptionId = 'chat_$chatId';

    // ✅ Отписываемся от STOMP
    if (_subscriptions.containsKey(subscriptionId)) {
      _subscriptions[subscriptionId]?.call();
      _subscriptions.remove(subscriptionId);
      debugPrint('📡 Unsubscribed from STOMP: $chatId');
    }

    // ✅ Удаляем из активных подписок
    if (_activeSubscriptions.contains(subscriptionId)) {
      _activeSubscriptions.remove(subscriptionId);
      debugPrint('📡 Removed from active subscriptions: $chatId');
    }
  }

  void sendMessage(int chatId, String content, {String? imageObjectName}) {
    if (!_isConnected || _stompClient == null) {
      debugPrint('⚠️ WebSocket not connected, cannot send message');
      return;
    }

    final message = {
      'chatId': chatId,
      'content': content,
    };

    if (imageObjectName != null && imageObjectName.isNotEmpty) {
      message['imageObjectName'] = imageObjectName;
    }

    _stompClient!.send(
      destination: '/app/chat.sendMessage',
      headers: {
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(message),
    );

    debugPrint('📤 Message sent to chat $chatId: ${content.length > 50 ? content.substring(0, 50) : content}...');
  }

  void markChatAsRead(int chatId) {
    if (!_isConnected || _stompClient == null) return;

    _stompClient!.send(
      destination: '/app/chat.markRead/$chatId',
      headers: {
        'Authorization': 'Bearer $_token',
      },
      body: '',
    );

    debugPrint('👁️ Marked chat $chatId as read');
  }

  void disconnect() {
    // ✅ Отписываемся от всех подписок
    for (final unsubscribe in _subscriptions.values) {
      unsubscribe.call();
    }
    _subscriptions.clear();
    _activeSubscriptions.clear();

    if (_stompClient != null) {
      _stompClient!.deactivate();
      _isConnected = false;
      debugPrint('🔌 WebSocket disconnected manually');
    }
  }

  bool get isConnected => _isConnected;

  Future<void> reconnect() async {
    disconnect();
    await connect();
  }
}