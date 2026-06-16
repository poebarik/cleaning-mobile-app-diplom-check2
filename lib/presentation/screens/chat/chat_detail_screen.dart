import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/image_uploader.dart';
import '../../providers/chat_provider.dart';
import '../../../data/models/chat/chat.dart';
import '../../../data/models/chat/message.dart';
import '../../providers/auth_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../routes/route_names.dart';

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
  bool _isDisposed = false;

  String get _otherPartyName {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;

    if (currentUserId == widget.chat.clientId) {
      return widget.chat.cleanerName;
    } else {
      return widget.chat.clientName;
    }
  }

  String get _otherPartyRole {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;

    if (currentUserId == widget.chat.clientId) {
      return 'Клинер';
    } else {
      return 'Клиент';
    }
  }

  int get _otherPartyId {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;

    if (currentUserId == widget.chat.clientId) {
      return widget.chat.cleanerId;
    } else {
      return widget.chat.clientId;
    }
  }

  String? get _otherPartyAvatar {
    final authState = ref.read(authProvider);
    final currentUserId = authState.user?.id;

    if (currentUserId == widget.chat.clientId) {
      return widget.chat.cleanerAvatarUrl;
    } else {
      return widget.chat.clientAvatarUrl;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _setupWebSocketListener();
        _loadMessages();
      }
    });
  }

  void _setupWebSocketListener() {
    ref.read(chatProvider.notifier).onMessageReceived = (message) {
      if (!_isDisposed && mounted && message.chatId == widget.chatId) {
        _scrollToBottom();
      }
    };
  }

  Future<void> _loadMessages() async {
    if (_isDisposed) return;
    await ref.read(chatProvider.notifier).loadMessages(widget.chatId);
    if (mounted && !_isDisposed) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!mounted || _isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted && _scrollController.hasClients) {
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

    // Отправляем сообщение с несколькими фото
    await ref.read(chatProvider.notifier).sendMessageWithImages(
      widget.chatId,
      content,
      _uploadedImages,
    );

    _messageController.clear();

    if (mounted && !_isDisposed) {
      setState(() {
        _uploadedImages = [];
        _isSending = false;
      });
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile', arguments: _otherPartyId);
  }

  void _showFullScreenImages(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messagesData = chatState.messagesData;
    final messages = messagesData?.$2 ?? [];

    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _navigateToProfile,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _otherPartyAvatar != null && _otherPartyAvatar!.isNotEmpty
                    ? CachedNetworkImageProvider(_otherPartyAvatar!)
                    : null,
                child: _otherPartyAvatar == null || _otherPartyAvatar!.isEmpty
                    ? Text(
                  _otherPartyName.isNotEmpty ? _otherPartyName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherPartyName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _otherPartyRole,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ],
          ),
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
                final isMe = message.senderId == currentUserId;
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
    final hasMultipleImages = message.imageObjectNames != null && message.imageObjectNames!.length > 1;
    final imageUrls = message.imageObjectNames?.map((name) => '${ApiConstants.baseUrl}/files/$name').toList() ?? [];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          if (message.imageObjectNames != null && message.imageObjectNames!.isNotEmpty) {
            _showFullScreenImages(imageUrls, 0);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
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
              if (!isMe)
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/profile', arguments: message.senderId),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: message.senderAvatarUrl != null && message.senderAvatarUrl!.isNotEmpty
                              ? CachedNetworkImageProvider(message.senderAvatarUrl!)
                              : null,
                          child: message.senderAvatarUrl == null || message.senderAvatarUrl!.isEmpty
                              ? Text(
                            message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Отображение нескольких фото
              if (message.imageObjectNames != null && message.imageObjectNames!.isNotEmpty) ...[
                if (hasMultipleImages)
                  _buildImageGrid(imageUrls)
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: imageUrls.first,
                        width: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey.shade200,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 200,
                          height: 150,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                    ),
                  ),
                if (hasMultipleImages)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${message.imageObjectNames!.length} фото',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
              if (message.content != null && message.content!.isNotEmpty)
                Padding(
                  padding: message.imageObjectNames != null && message.imageObjectNames!.isNotEmpty
                      ? const EdgeInsets.only(top: 8)
                      : EdgeInsets.zero,
                  child: Text(
                    message.content!,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
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
      ),
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: imageUrls.length > 4 ? 4 : imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image),
            ),
          ),
        );
      },
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
      child: Column(
        children: [
          if (_uploadedImages.isNotEmpty)
            Container(
              height: 80,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _uploadedImages.length,
                itemBuilder: (context, index) {
                  final imageUrl = '${ApiConstants.baseUrl}/files/${_uploadedImages[index]}';
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          Row(
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              title: const Text('Выбрать из галереи (до 5 фото)'),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
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

  Future<void> _pickMultipleImages() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Загрузить фото (до 5 шт)'),
        content: SizedBox(
          width: 300,
          child: ImageUploader(
            onImagesUploaded: (objectNames) {
              Navigator.pop(context, objectNames);
            },
            folder: 'chats',
            maxImages: 5 - _uploadedImages.length,
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted && !_isDisposed) {
      setState(() {
        _uploadedImages.addAll(result);
      });
    }
  }

  Future<void> _takePhoto() async {
    // TODO: Implement camera functionality
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}