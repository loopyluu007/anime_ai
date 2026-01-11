/// 对话模型
class Conversation {
  final String id;
  final String userId;
  final String title;
  final String? previewText;
  final int messageCount;
  final bool isPinned;
  final DateTime lastAccessedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    required this.title,
    this.previewText,
    this.messageCount = 0,
    this.isPinned = false,
    required this.lastAccessedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      title: json['title'] as String,
      previewText: json['preview_text'] as String? ?? json['previewText'] as String?,
      messageCount: json['message_count'] as int? ?? json['messageCount'] as int? ?? 0,
      isPinned: json['is_pinned'] as bool? ?? json['isPinned'] as bool? ?? false,
      lastAccessedAt: DateTime.parse(
        json['last_accessed_at'] as String? ?? json['lastAccessedAt'] as String,
      ),
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? json['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] as String? ?? json['updatedAt'] as String,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'preview_text': previewText,
      'message_count': messageCount,
      'is_pinned': isPinned,
      'last_accessed_at': lastAccessedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 创建副本并更新字段
  Conversation copyWith({
    String? title,
    String? previewText,
    int? messageCount,
    bool? isPinned,
    DateTime? lastAccessedAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      title: title ?? this.title,
      previewText: previewText ?? this.previewText,
      messageCount: messageCount ?? this.messageCount,
      isPinned: isPinned ?? this.isPinned,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 分页响应
class PaginatedResponse<T> {
  final int page;
  final int pageSize;
  final int total;
  final List<T> items;

  PaginatedResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse<T>(
      page: json['page'] as int,
      pageSize: json['page_size'] as int? ?? json['pageSize'] as int,
      total: json['total'] as int,
      items: (json['items'] as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 是否有下一页
  bool get hasNext => page * pageSize < total;

  /// 是否有上一页
  bool get hasPrevious => page > 1;
}
