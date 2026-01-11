import 'scene.dart';
import 'character_sheet.dart';

enum ScreenplayStatus {
  draft,
  confirmed,
  generating,
  completed,
  failed;

  static ScreenplayStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return ScreenplayStatus.confirmed;
      case 'generating':
        return ScreenplayStatus.generating;
      case 'completed':
        return ScreenplayStatus.completed;
      case 'failed':
        return ScreenplayStatus.failed;
      default:
        return ScreenplayStatus.draft;
    }
  }
}

class Screenplay {
  final String id;
  final String taskId;
  final String userId;
  final String title;
  final ScreenplayStatus status;
  final List<Scene> scenes;
  final List<CharacterSheet> characterSheets;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Screenplay({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.title,
    required this.status,
    this.scenes = const [],
    this.characterSheets = const [],
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Screenplay.fromJson(Map<String, dynamic> json) {
    return Screenplay(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? json['task_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      title: json['title'] ?? '',
      status: ScreenplayStatus.fromString(json['status'] ?? 'draft'),
      scenes: json['scenes'] != null
          ? (json['scenes'] as List)
              .map((s) => Scene.fromJson(s))
              .toList()
          : [],
      characterSheets: json['characterSheets'] != null
          ? (json['characterSheets'] as List)
              .map((c) => CharacterSheet.fromJson(c))
              .toList()
          : (json['character_sheets'] != null
              ? (json['character_sheets'] as List)
                  .map((c) => CharacterSheet.fromJson(c))
                  .toList()
              : []),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : (json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : DateTime.now()),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'title': title,
      'status': status.name,
      'scenes': scenes.map((s) => s.toJson()).toList(),
      'characterSheets': characterSheets.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  bool get isDraft => status == ScreenplayStatus.draft;
  bool get isConfirmed => status == ScreenplayStatus.confirmed;
  bool get isGenerating => status == ScreenplayStatus.generating;
  bool get isCompleted => status == ScreenplayStatus.completed;
  bool get isFailed => status == ScreenplayStatus.failed;
}
