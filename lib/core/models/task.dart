/// 任务类型
enum TaskType {
  screenplay,
  image,
  video,
}

/// 任务状态
enum TaskStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// 任务进度
class TaskProgress {
  final TaskStatus status;
  final int progress;
  final String? currentStep;
  final Map<String, dynamic>? details;

  TaskProgress({
    required this.status,
    required this.progress,
    this.currentStep,
    this.details,
  });

  factory TaskProgress.fromJson(Map<String, dynamic> json) {
    return TaskProgress(
      status: _parseStatus(json['status']),
      progress: json['progress'] ?? 0,
      currentStep: json['currentStep'],
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'])
          : null,
    );
  }

  static TaskStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return TaskStatus.pending;
      case 'processing':
        return TaskStatus.processing;
      case 'completed':
        return TaskStatus.completed;
      case 'failed':
        return TaskStatus.failed;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'progress': progress,
      'currentStep': currentStep,
      'details': details,
    };
  }
}

/// 任务模型
class Task {
  final String id;
  final TaskType type;
  final String? conversationId;
  final Map<String, dynamic> params;
  final TaskStatus status;
  final int progress;
  final Map<String, dynamic>? result;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.type,
    this.conversationId,
    required this.params,
    required this.status,
    this.progress = 0,
    this.result,
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '',
      type: _parseType(json['type']),
      conversationId: json['conversationId']?.toString(),
      params: Map<String, dynamic>.from(json['params'] ?? {}),
      status: TaskProgress._parseStatus(json['status']),
      progress: json['progress'] ?? 0,
      result: json['result'] != null
          ? Map<String, dynamic>.from(json['result'])
          : null,
      errorMessage: json['errorMessage'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }

  static TaskType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'screenplay':
        return TaskType.screenplay;
      case 'image':
        return TaskType.image;
      case 'video':
        return TaskType.video;
      default:
        return TaskType.screenplay;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'conversationId': conversationId,
      'params': params,
      'status': status.name,
      'progress': progress,
      'result': result,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}

/// 创建任务请求
class TaskCreateRequest {
  final TaskType type;
  final String? conversationId;
  final Map<String, dynamic> params;

  TaskCreateRequest({
    required this.type,
    this.conversationId,
    required this.params,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (conversationId != null) 'conversationId': conversationId,
      'params': params,
    };
  }
}
