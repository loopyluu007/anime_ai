import 'api_client.dart';
import '../../features/chat/models/conversation.dart';
import '../../features/chat/models/message.dart';

/// 对话客户端
class ConversationClient {
  final ApiClient _apiClient;

  ConversationClient(this._apiClient);

  /// 创建对话
  Future<Conversation> createConversation(String title) async {
    final response = await _apiClient.post(
      '/conversations',
      data: {'title': title},
    );
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 获取对话列表
  Future<PaginatedResponse<Conversation>> getConversations({
    int page = 1,
    int pageSize = 20,
    bool? pinned,
  }) async {
    final response = await _apiClient.get(
      '/conversations',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (pinned != null) 'pinned': pinned,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      (json) => Conversation.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取对话详情
  Future<Conversation> getConversation(String id) async {
    final response = await _apiClient.get('/conversations/$id');
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 更新对话
  Future<Conversation> updateConversation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      '/conversations/$id',
      data: data,
    );
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 删除对话
  Future<void> deleteConversation(String id) async {
    await _apiClient.delete('/conversations/$id');
  }

  /// 获取消息列表
  Future<PaginatedResponse<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get(
      '/conversations/$conversationId/messages',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      (json) => Message.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 发送消息
  Future<Message> sendMessage(
    String conversationId,
    String content, {
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiClient.post(
      '/conversations/$conversationId/messages',
      data: {
        'role': 'user',
        'content': content,
        'type': type.name,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return Message.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
