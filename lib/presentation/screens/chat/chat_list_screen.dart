import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../providers/chat_provider.dart';
import '../../../routes/route_names.dart';
import '../../../data/models/chat/chat.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).loadChats();
      ref.read(chatProvider.notifier).connectWebSocket();
    });
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).disconnectWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(chatProvider.notifier).loadChats();
        },
        child: chatState.isLoading
            ? const ShimmerLoading(child: SizedBox(height: 80))
            : chatState.isChatsLoaded && chatState.chats!.isNotEmpty
            ? ListView.builder(
          itemCount: chatState.chats!.length,
          itemBuilder: (context, index) {
            final chat = chatState.chats![index];
            return _buildChatTile(chat);
          },
        )
            : const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Нет чатов'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(Chat chat) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Text(
          chat.cleanerName[0],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        chat.cleanerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        chat.lastMessage?.content ?? 'Напишите сообщение...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount.toString(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          Text(
            _formatTime(chat.updatedAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
      onTap: () async {
        await ref.read(chatProvider.notifier).markChatAsRead(chat.id);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(chatId: chat.id, chat: chat),
          ),
        ).then((_) {
          ref.read(chatProvider.notifier).loadChats();
        });
      },
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}д';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}ч';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}м';
    } else {
      return 'только что';
    }
  }
}