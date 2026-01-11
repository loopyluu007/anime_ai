/// 消息角色
enum MessageRole {
  user,
  assistant,
}

/// 消息类型
enum MessageType {
  text,
  image,
  video,
  screenplay,
}

/// 消息模型
class Message {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.metadata,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String? ?? json['conversationId'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String? ?? json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role.name,
      'content': content,
      'type': type.name,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 是否为用户消息
  bool get isUser => role == MessageRole.user;

  /// 是否为助手消息
  bool get isAssistant => role == MessageRole.assistant;

  /// 是否为剧本消息
  bool get isScreenplay => type == MessageType.screenplay;

  /// 获取剧本ID（如果是剧本消息）
  String? get screenplayId {
    if (isScreenplay && metadata != null) {
      return metadata!['screenplayId'] as String?;
    }
    return null;
  }
}
