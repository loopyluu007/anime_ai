/// 对话模型
class Conversation {
  final String id;
  final String title;
  final String? previewText;
  final int messageCount;
  final bool isPinned;
  final DateTime lastAccessedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.title,
    this.previewText,
    this.messageCount = 0,
    this.isPinned = false,
    required this.lastAccessedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      previewText: json['previewText'],
      messageCount: json['messageCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'previewText': previewText,
      'messageCount': messageCount,
      'isPinned': isPinned,
      'lastAccessedAt': lastAccessedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
