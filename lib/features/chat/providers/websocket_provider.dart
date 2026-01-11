import 'package:flutter/foundation.dart';
import '../../../core/api/websocket_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'chat_provider.dart';
import 'conversation_provider.dart';

/// WebSocket 状态管理 Provider
class WebSocketProvider extends ChangeNotifier {
  WebSocketClient? _client;
  final Future<String?> Function()? getToken;
  ChatProvider? _chatProvider;
  ConversationProvider? _conversationProvider;

  WebSocketProvider({this.getToken});

  /// WebSocket 客户端
  WebSocketClient? get client => _client;

  /// 连接状态
  WebSocketStatus get status => _client?.status ?? WebSocketStatus.disconnected;

  /// 是否已连接
  bool get isConnected => _client?.isConnected ?? false;

  /// 设置 ChatProvider（用于接收消息）
  void setChatProvider(ChatProvider provider) {
    _chatProvider = provider;
  }

  /// 设置 ConversationProvider（用于更新对话列表）
  void setConversationProvider(ConversationProvider provider) {
    _conversationProvider = provider;
  }

  /// 初始化并连接 WebSocket
  Future<void> initialize() async {
    if (_client != null && _client!.isConnected) {
      return;
    }

    _client = WebSocketClient(getToken: getToken);

    // 设置消息回调
    _client!.onMessage = _handleMessage;
    _client!.onStatusChanged = _handleStatusChanged;
    _client!.onError = _handleError;

    // 连接
    await _client!.connect();
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _client?.disconnect();
    _client = null;
    notifyListeners();
  }

  /// 订阅对话消息
  void subscribeConversation(String conversationId) {
    if (_client == null || !_client!.isConnected) {
      return;
    }

    _client!.subscribe(
      'message.new',
      conversationId: conversationId,
    );
  }

  /// 取消订阅对话消息
  void unsubscribeConversation(String conversationId) {
    if (_client == null || !_client!.isConnected) {
      return;
    }

    _client!.unsubscribe(
      'message.new',
      conversationId: conversationId,
    );
  }

  /// 订阅任务进度
  void subscribeTask(String taskId) {
    if (_client == null || !_client!.isConnected) {
      return;
    }

    _client!.subscribe(
      'task.progress',
      taskId: taskId,
    );
  }

  /// 取消订阅任务进度
  void unsubscribeTask(String taskId) {
    if (_client == null || !_client!.isConnected) {
      return;
    }

    _client!.unsubscribe(
      'task.progress',
      taskId: taskId,
    );
  }

  /// 处理接收到的消息
  void _handleMessage(WebSocketMessageType type, Map<String, dynamic> data) {
    switch (type) {
      case WebSocketMessageType.messageNew:
        _handleNewMessage(data);
        break;
      case WebSocketMessageType.taskProgress:
        _handleTaskProgress(data);
        break;
      case WebSocketMessageType.taskCompleted:
        _handleTaskCompleted(data);
        break;
      case WebSocketMessageType.taskFailed:
        _handleTaskFailed(data);
        break;
      default:
        break;
    }
  }

  /// 处理新消息
  void _handleNewMessage(Map<String, dynamic> data) {
    try {
      final conversationId = data['conversationId'] as String?;
      final messageId = data['messageId'] as String?;
      final content = data['content'] as String?;

      if (conversationId == null || messageId == null) {
        return;
      }

      // 如果当前对话是接收消息的对话，则添加到消息列表
      if (_chatProvider?.currentConversation?.id == conversationId) {
        // 使用 WebSocket 推送的数据构造消息对象
        // 注意：这里假设服务器推送了完整的消息数据
        // 如果服务器只推送了 messageId，需要调用 API 获取完整消息
        final message = Message(
          id: messageId,
          conversationId: conversationId,
          role: MessageRole.assistant,
          content: content ?? '',
          type: MessageType.text,
          createdAt: DateTime.now(),
        );

        _chatProvider?.addMessage(message);
      }

      // 更新对话列表（刷新预览文本等）
      _conversationProvider?.loadConversations(refresh: true);

      notifyListeners();
    } catch (e) {
      debugPrint('处理新消息失败: $e');
    }
  }

  /// 处理任务进度
  void _handleTaskProgress(Map<String, dynamic> data) {
    // 这里可以通知任务相关的 Provider 更新进度
    // 例如：TaskProvider.updateProgress(taskId, progress)
    notifyListeners();
  }

  /// 处理任务完成
  void _handleTaskCompleted(Map<String, dynamic> data) {
    // 这里可以通知任务相关的 Provider 任务已完成
    notifyListeners();
  }

  /// 处理任务失败
  void _handleTaskFailed(Map<String, dynamic> data) {
    // 这里可以通知任务相关的 Provider 任务失败
    notifyListeners();
  }

  /// 处理状态变化
  void _handleStatusChanged(WebSocketStatus status) {
    notifyListeners();
  }

  /// 处理错误
  void _handleError(String error) {
    debugPrint('WebSocket 错误: $error');
    notifyListeners();
  }

  @override
  void dispose() {
    _client?.dispose();
    super.dispose();
  }
}
