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
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      role: _parseRole(json['role']),
      content: json['content'] ?? '',
      type: _parseType(json['type']),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  static MessageRole _parseRole(String? role) {
    switch (role?.toLowerCase()) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      default:
        return MessageRole.user;
    }
  }

  static MessageType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'video':
        return MessageType.video;
      case 'screenplay':
        return MessageType.screenplay;
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'role': role.name,
      'content': content,
      'type': type.name,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
