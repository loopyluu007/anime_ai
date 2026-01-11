import 'package:flutter/foundation.dart';
import '../../../core/api/task_client.dart';
import '../../../core/api/conversation_client.dart' show PaginatedResponse;
import '../../../core/models/task.dart';
import '../../chat/providers/websocket_provider.dart';

/// 任务状态管理
class TaskProvider extends ChangeNotifier {
  final TaskClient _client;
  WebSocketProvider? _websocketProvider;

  TaskProvider(this._client);

  /// 设置 WebSocket Provider
  void setWebSocketProvider(WebSocketProvider provider) {
    _websocketProvider = provider;
    // 可以在这里监听任务相关的WebSocket事件
  }

  List<Task> _tasks = [];
  Task? _currentTask;
  TaskProgress? _currentTaskProgress;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  TaskType? _filterType;
  TaskStatus? _filterStatus;

  List<Task> get tasks => _tasks;
  Task? get currentTask => _currentTask;
  TaskProgress? get currentTaskProgress => _currentTaskProgress;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get error => _error;
  bool get hasMore => _hasMore;
  TaskType? get filterType => _filterType;
  TaskStatus? get filterStatus => _filterStatus;

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 设置筛选条件
  void setFilters({TaskType? type, TaskStatus? status}) {
    _filterType = type;
    _filterStatus = status;
    loadTasks(refresh: true);
  }

  /// 清除筛选条件
  void clearFilters() {
    _filterType = null;
    _filterStatus = null;
    loadTasks(refresh: true);
  }

  /// 加载任务列表
  Future<void> loadTasks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _tasks.clear();
    }

    if (!_hasMore || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client.getTasks(
        page: _currentPage,
        pageSize: 20,
        type: _filterType,
        status: _filterStatus,
      );

      if (refresh) {
        _tasks = response.items;
      } else {
        _tasks.addAll(response.items);
      }

      _hasMore = response.items.length >= 20; // 如果返回的数量等于pageSize，可能还有更多
      _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载任务详情
  Future<void> loadTaskDetail(String taskId) async {
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      _currentTask = await _client.getTask(taskId);
      await loadTaskProgress(taskId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  /// 加载任务进度
  Future<void> loadTaskProgress(String taskId) async {
    try {
      _currentTaskProgress = await _client.getTaskProgress(taskId);
      // 同时更新任务列表中的任务状态
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = await _client.getTask(taskId);
      }
      notifyListeners();
    } catch (e) {
      // 进度加载失败不影响详情显示
      debugPrint('加载任务进度失败: $e');
    }
  }

  /// 刷新当前任务
  Future<void> refreshCurrentTask() async {
    if (_currentTask != null) {
      await loadTaskDetail(_currentTask!.id);
    }
  }

  /// 取消任务
  Future<bool> cancelTask(String taskId) async {
    try {
      await _client.cancelTask(taskId);
      // 刷新任务列表
      await loadTaskDetail(taskId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 删除任务
  Future<bool> deleteTask(String taskId) async {
    try {
      await _client.deleteTask(taskId);
      // 从列表中移除
      _tasks.removeWhere((t) => t.id == taskId);
      // 如果删除的是当前任务，清空当前任务
      if (_currentTask?.id == taskId) {
        _currentTask = null;
        _currentTaskProgress = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// 创建任务
  Future<Task?> createTask(TaskCreateRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = await _client.createTask(request);
      _tasks.insert(0, task);
      notifyListeners();
      return task;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
    }
  }

  /// 更新任务（从WebSocket或其他来源）
  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
    if (_currentTask?.id == task.id) {
      _currentTask = task;
    }
    notifyListeners();
  }

  /// 更新任务进度（从WebSocket或其他来源）
  void updateTaskProgress(String taskId, TaskProgress progress) {
    _currentTaskProgress = progress;
    // 更新任务列表中的任务
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      loadTaskDetail(taskId); // 异步刷新任务详情
    }
    notifyListeners();
  }
}
