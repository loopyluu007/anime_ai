import 'package:flutter/foundation.dart';
import '../../../core/api/conversation_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import 'websocket_provider.dart';

/// 聊天状态管理
class ChatProvider extends ChangeNotifier {
  final ConversationClient _client;
  WebSocketProvider? _websocketProvider;

  ChatProvider(this._client);

  /// 设置 WebSocket Provider
  void setWebSocketProvider(WebSocketProvider provider) {
    _websocketProvider = provider;
    provider.setChatProvider(this);
  }

  Conversation? _currentConversation;
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  Conversation? get currentConversation => _currentConversation;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// 设置当前对话
  void setConversation(Conversation conversation) {
    // 取消订阅之前的对话
    if (_currentConversation != null && _websocketProvider != null) {
      _websocketProvider!.unsubscribeConversation(_currentConversation!.id);
    }

    _currentConversation = conversation;
    _messages.clear();
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
    loadMessages();

    // 订阅新对话的 WebSocket 消息
    if (_websocketProvider != null && conversation.id.isNotEmpty) {
      _websocketProvider!.subscribeConversation(conversation.id);
    }
  }

  /// 加载消息列表
  Future<void> loadMessages({bool refresh = false}) async {
    if (_currentConversation == null) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _messages.clear();
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.getMessages(
        _currentConversation!.id,
        page: _currentPage,
        pageSize: 50,
      );

      if (refresh) {
        _messages = response.items.reversed.toList();
      } else {
        _messages.insertAll(0, response.items.reversed.toList());
      }

      _hasMore = response.hasNext;
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 发送消息
  Future<Message?> sendMessage(
    String content, {
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentConversation == null || content.trim().isEmpty) {
      return null;
    }

    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      final message = await _client.sendMessage(
        _currentConversation!.id,
        content,
        type: type,
        metadata: metadata,
      );
      _messages.add(message);
      notifyListeners();
      return message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isSending = false;
    }
  }

  /// 添加消息（用于WebSocket接收）
  void addMessage(Message message) {
    if (message.conversationId == _currentConversation?.id) {
      _messages.add(message);
      notifyListeners();
    }
  }

  /// 更新消息
  void updateMessage(Message message) {
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      _messages[index] = message;
      notifyListeners();
    }
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 重置状态
  void reset() {
    // 取消订阅 WebSocket
    if (_currentConversation != null && _websocketProvider != null) {
      _websocketProvider!.unsubscribeConversation(_currentConversation!.id);
    }

    _currentConversation = null;
    _messages.clear();
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    _isLoading = false;
    _isSending = false;
    notifyListeners();
  }
}
