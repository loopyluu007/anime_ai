import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/conversation_provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/screenplay_card.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/conversation_client.dart';
import '../../../core/storage/local_storage.dart';

/// 聊天界面
class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({
    Key? key,
    required this.conversation,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取或创建ChatProvider
    final apiClient = ApiClient(
      getToken: () async => await LocalStorage.getString('auth_token'),
    );
    final conversationClient = ConversationClient(apiClient);
    
    return ChangeNotifierProvider(
      create: (_) {
        final provider = ChatProvider(conversationClient);
        // 设置对话
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.setConversation(widget.conversation);
        });
        return provider;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.conversation.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMenu(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null && provider.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '加载失败',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.clearError();
                              provider.loadMessages(refresh: true);
                            },
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (provider.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '开始对话',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadMessages(refresh: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: provider.messages.length +
                          (provider.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.messages.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final message = provider.messages[
                            provider.messages.length - 1 - index];

                        if (message.isScreenplay) {
                          return ScreenplayCard(
                            message: message,
                            onTap: () {
                              // TODO: 导航到剧本详情页
                            },
                          );
                        }

                        return MessageBubble(message: message);
                      },
                    ),
                  );
                },
              ),
            ),
            Consumer<ChatProvider>(
              builder: (context, provider, child) {
                return MessageInput(
                  onSend: (text) {
                    provider.sendMessage(text).then((_) {
                      _scrollToBottom();
                    });
                  },
                  isSending: provider.isSending,
                );
              },
            ),
            // 监听消息变化，自动滚动到底部
            Consumer<ChatProvider>(
              builder: (context, provider, child) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑标题'),
              onTap: () {
                Navigator.pop(context);
                _showEditTitleDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除对话'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTitleDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.conversation.title);
    final provider = context.read<ConversationProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑标题'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入新标题',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                provider.updateConversation(widget.conversation.id, {
                  'title': title,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    final provider = context.read<ConversationProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话'),
        content: Text('确定要删除"${widget.conversation.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteConversation(widget.conversation.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
