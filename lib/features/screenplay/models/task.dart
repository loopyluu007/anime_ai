enum TaskStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class Task {
  final String id;
  final String screenplayId;
  final TaskStatus status;
  final int progress;
  final String? errorMessage;
  final Map<String, dynamic>? result;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  
  Task({
    required this.id,
    required this.screenplayId,
    required this.status,
    this.progress = 0,
    this.errorMessage,
    this.result,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });
  
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      screenplayId: json['screenplayId'] ?? '',
      status: _parseStatus(json['status'] ?? 'pending'),
      progress: json['progress'] ?? 0,
      errorMessage: json['errorMessage'],
      result: json['result'],
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
  
  static TaskStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
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
      'id': id,
      'screenplayId': screenplayId,
      'status': status.name,
      'progress': progress,
      'errorMessage': errorMessage,
      'result': result,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }
  
  bool get isPending => status == TaskStatus.pending;
  bool get isProcessing => status == TaskStatus.processing;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isFailed => status == TaskStatus.failed;
  bool get isCancelled => status == TaskStatus.cancelled;
}
