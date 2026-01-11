import 'api_client.dart';
import '../models/task.dart';
import 'conversation_client.dart' show PaginatedResponse;

/// 任务客户端
class TaskClient {
  final ApiClient _apiClient;

  TaskClient(this._apiClient);

  /// 创建任务
  Future<Task> createTask(TaskCreateRequest request) async {
    final response = await _apiClient.post(
      '/tasks',
      data: request.toJson(),
    );
    return Task.fromJson(response.data['data']);
  }

  /// 获取任务列表
  Future<PaginatedResponse<Task>> getTasks({
    int page = 1,
    int pageSize = 20,
    TaskType? type,
    TaskStatus? status,
  }) async {
    final response = await _apiClient.get(
      '/tasks',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (type != null) 'type': type.name,
        if (status != null) 'status': status.name,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'],
      (json) => Task.fromJson(json),
    );
  }

  /// 获取任务详情
  Future<Task> getTask(String id) async {
    final response = await _apiClient.get('/tasks/$id');
    return Task.fromJson(response.data['data']);
  }

  /// 获取任务进度
  Future<TaskProgress> getTaskProgress(String id) async {
    final response = await _apiClient.get('/tasks/$id/progress');
    return TaskProgress.fromJson(response.data['data']);
  }

  /// 取消任务
  Future<void> cancelTask(String id) async {
    await _apiClient.post('/tasks/$id/cancel');
  }

  /// 删除任务
  Future<void> deleteTask(String id) async {
    await _apiClient.delete('/tasks/$id');
  }
}
