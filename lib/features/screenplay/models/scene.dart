enum SceneStatus {
  pending,
  generating,
  completed,
  failed;

  static SceneStatus fromString(String status) {
    switch (status.toLowerCase()) {
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
}

class Scene {
  final String id;
  final String screenplayId;
  final int sceneId;
  final String narration;
  final String imagePrompt;
  final String videoPrompt;
  final String? characterDescription;
  final String? imageUrl;
  final String? videoUrl;
  final SceneStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Scene({
    required this.id,
    required this.screenplayId,
    required this.sceneId,
    required this.narration,
    required this.imagePrompt,
    required this.videoPrompt,
    this.characterDescription,
    this.imageUrl,
    this.videoUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Scene.fromJson(Map<String, dynamic> json) {
    return Scene(
      id: json['id']?.toString() ?? '',
      screenplayId: json['screenplayId']?.toString() ?? json['screenplay_id']?.toString() ?? '',
      sceneId: json['sceneId'] ?? json['scene_id'] ?? 0,
      narration: json['narration'] ?? '',
      imagePrompt: json['imagePrompt'] ?? json['image_prompt'] ?? '',
      videoPrompt: json['videoPrompt'] ?? json['video_prompt'] ?? '',
      characterDescription: json['characterDescription'] ?? json['character_description'],
      imageUrl: json['imageUrl'] ?? json['image_url'],
      videoUrl: json['videoUrl'] ?? json['video_url'],
      status: SceneStatus.fromString(json['status'] ?? 'pending'),
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
      'screenplayId': screenplayId,
      'sceneId': sceneId,
      'narration': narration,
      'imagePrompt': imagePrompt,
      'videoPrompt': videoPrompt,
      'characterDescription': characterDescription,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == SceneStatus.pending;
  bool get isGenerating => status == SceneStatus.generating;
  bool get isCompleted => status == SceneStatus.completed;
  bool get isFailed => status == SceneStatus.failed;
}
