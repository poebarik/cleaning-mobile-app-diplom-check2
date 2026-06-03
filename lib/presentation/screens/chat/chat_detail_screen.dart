import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/image_uploader.dart';
import '../../providers/chat_provider.dart';
import '../../../data/models/chat/chat.dart';
import '../../../data/models/chat/message.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final int chatId;
  final Chat chat;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chat,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> _uploadedImages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // ✅ ОТЛАГИВАЕМ ЗАГРУЗКУ СООБЩЕНИЙ ДО СЛЕДУЮЩЕГО ФРЕЙМА
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMessages();
      }
    });
  }



  Future<void> _loadMessages() async {
    await ref.read(chatProvider.notifier).loadMessages(widget.chatId);

    if (mounted) {
      _scrollToBottom();
    }
  }

  void _addNewMessage(Message message) {
    final currentState = ref.read(chatProvider);
    if (currentState.isMessagesLoaded) {
      final messagesData = currentState.messagesData;
      if (messagesData != null && messagesData.$1 == widget.chatId) {
        final updatedMessages = [...messagesData.$2, message];
        ref.read(chatProvider.notifier).updateMessages(updatedMessages);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _uploadedImages.isEmpty) return;
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    String? imageObjectName;
    if (_uploadedImages.isNotEmpty) {
      imageObjectName = _uploadedImages.first;
    }

    await ref.read(chatProvider.notifier).sendMessage(
      widget.chatId,
      content,
      imageObjectName: imageObjectName,
    );

    _messageController.clear();

    setState(() {
      _uploadedImages = [];
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messagesData = chatState.messagesData;
    final messages = messagesData?.$2 ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chat.cleanerName),
            const Text(
              'Клинер',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Начните диалог'),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message.senderId == widget.chat.clientId;
                return _buildMessageBubble(message, isMe);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.imageUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50);
                    },
                  ),
                ),
              ),
            if (message.content != null && message.content!.isNotEmpty)
              Text(
                message.content!,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_camera),
            onPressed: _showImagePicker,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Напишите сообщение...',
                border: InputBorder.none,
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          if (_uploadedImages.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text('${_uploadedImages.length}'),
                ],
              ),
            ),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Загрузить фото'),
        content: SizedBox(
          width: 300,
          child: ImageUploader(
            onImagesUploaded: (objectNames) {
              Navigator.pop(context, objectNames);
            },
            folder: 'chats',
            maxImages: 1,
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _uploadedImages = result;
      });
    }
  }

  Future<void> _takePhoto() async {
    // TODO: Implement camera functionality
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}