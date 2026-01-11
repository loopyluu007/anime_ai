/// 场景状态
enum SceneStatus {
  pending,
  generating,
  completed,
  failed,
}

/// 场景模型
class Scene {
  final String id;
  final int sceneId;
  final String screenplayId;
  final String narration;
  final String imagePrompt;
  final String videoPrompt;
  final String? characterDescription;
  final String? imageUrl;
  final String? videoUrl;
  final SceneStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Scene({
    required this.id,
    required this.sceneId,
    required this.screenplayId,
    required this.narration,
    required this.imagePrompt,
    required this.videoPrompt,
    this.characterDescription,
    this.imageUrl,
    this.videoUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id']?.toString() ?? '',
      sceneId: json['sceneId'] ?? 0,
      screenplayId: json['screenplayId']?.toString() ?? '',
      narration: json['narration'] ?? '',
      imagePrompt: json['imagePrompt'] ?? '',
      videoPrompt: json['videoPrompt'] ?? '',
      characterDescription: json['characterDescription'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  static SceneStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return SceneStatus.pending;
      case 'generating':
        return SceneStatus.generating;
      case 'completed':
        return SceneStatus.completed;
      case 'failed':
        return SceneStatus.failed;
      default:
        return SceneStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sceneId': sceneId,
      'screenplayId': screenplayId,
      'narration': narration,
      'imagePrompt': imagePrompt,
      'videoPrompt': videoPrompt,
      'characterDescription': characterDescription,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// 角色设定模型
class CharacterSheet {
  final String id;
  final String screenplayId;
  final String name;
  final String? description;
  final String? combinedViewUrl;
  final String? frontViewUrl;
  final String? sideViewUrl;
  final String? backViewUrl;
  final DateTime createdAt;

  CharacterSheet({
    required this.id,
    required this.screenplayId,
    required this.name,
    this.description,
    this.combinedViewUrl,
    this.frontViewUrl,
    this.sideViewUrl,
    this.backViewUrl,
    required this.createdAt,
  });

  factory CharacterSheet.fromJson(Map<String, dynamic> json) {
    return CharacterSheet(
      id: json['id']?.toString() ?? '',
      screenplayId: json['screenplayId']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      combinedViewUrl: json['combinedViewUrl'],
      frontViewUrl: json['frontViewUrl'],
      sideViewUrl: json['sideViewUrl'],
      backViewUrl: json['backViewUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'screenplayId': screenplayId,
      'name': name,
      'description': description,
      'combinedViewUrl': combinedViewUrl,
      'frontViewUrl': frontViewUrl,
      'sideViewUrl': sideViewUrl,
      'backViewUrl': backViewUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 剧本状态
enum ScreenplayStatus {
  draft,
  confirmed,
  generating,
  completed,
  failed,
}

/// 剧本模型
class Screenplay {
  final String id;
  final String taskId;
  final String title;
  final ScreenplayStatus status;
  final List<Scene> scenes;
  final List<CharacterSheet> characterSheets;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Screenplay({
    required this.id,
    required this.taskId,
    required this.title,
    required this.status,
    this.scenes = const [],
    this.characterSheets = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Screenplay.fromJson(Map<String, dynamic> json) {
    return Screenplay(
      id: json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      title: json['title'] ?? '',
      status: _parseStatus(json['status']),
      scenes: (json['scenes'] as List? ?? [])
          .map((item) => Scene.fromJson(item as Map<String, dynamic>))
          .toList(),
      characterSheets: (json['characterSheets'] as List? ?? [])
          .map((item) => CharacterSheet.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  static ScreenplayStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'draft':
        return ScreenplayStatus.draft;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'status': status.name,
      'scenes': scenes.map((scene) => scene.toJson()).toList(),
      'characterSheets': characterSheets.map((sheet) => sheet.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// 生成剧本草稿请求
class ScreenplayDraftRequest {
  final String taskId;
  final String prompt;
  final List<String>? userImages;
  final int sceneCount;
  final int characterCount;

  ScreenplayDraftRequest({
    required this.taskId,
    required this.prompt,
    this.userImages,
    this.sceneCount = 7,
    this.characterCount = 2,
  });

  Map<String, dynamic> toJson() {
    return {
      'taskId': taskId,
      'prompt': prompt,
      if (userImages != null) 'userImages': userImages,
      'sceneCount': sceneCount,
      'characterCount': characterCount,
    };
  }
}

/// 确认剧本请求
class ScreenplayConfirmRequest {
  final String? feedback;

  ScreenplayConfirmRequest({this.feedback});

  Map<String, dynamic> toJson() {
    return {
      if (feedback != null) 'feedback': feedback,
    };
  }
}
