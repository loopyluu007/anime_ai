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
