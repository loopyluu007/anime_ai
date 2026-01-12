import 'package:flutter/foundation.dart';
import '../../../core/api/conversation_client.dart';
import '../models/conversation.dart';
import 'websocket_provider.dart';

/// 对话状态管理
class ConversationProvider extends ChangeNotifier {
  final ConversationClient _client;
  WebSocketProvider? _websocketProvider;

  ConversationProvider(this._client);

  /// 设置 WebSocket Provider
  void setWebSocketProvider(WebSocketProvider provider) {
    _websocketProvider = provider;
    provider.setConversationProvider(this);
  }

  List<Conversation> _conversations = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Conversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// 加载对话列表
  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _conversations.clear();
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.getConversations(
        page: _currentPage,
        pageSize: 20,
      );

      if (refresh) {
        _conversations = response.items;
      } else {
        _conversations.addAll(response.items);
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

  /// 创建对话
  Future<Conversation?> createConversation(String title) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _client.createConversation(title);
      _conversations.insert(0, conversation);
      notifyListeners();
      return conversation;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  /// 更新对话
  Future<void> updateConversation(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final updated = await _client.updateConversation(id, data);
      final index = _conversations.indexWhere((c) => c.id == id);
      if (index != -1) {
        _conversations[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 删除对话
  Future<void> deleteConversation(String id) async {
    try {
      await _client.deleteConversation(id);
      _conversations.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// 置顶/取消置顶对话
  Future<void> togglePin(String id) async {
    final conversation = _conversations.firstWhere((c) => c.id == id);
    await updateConversation(id, {'isPinned': !conversation.isPinned});
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
