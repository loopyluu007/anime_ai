import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/task_client.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final TaskClient _client;
  
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  TaskProvider() : _client = TaskClient(ApiClient());
  
  Future<void> loadTasks({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _tasks = await _client.getTasks(status: status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Task> getTask(String taskId) async {
    try {
      return await _client.getTask(taskId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<Task> createTask(String screenplayId, {Map<String, dynamic>? options}) async {
    try {
      return await _client.createTask(
        screenplayId: screenplayId,
        options: options,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  Future<void> cancelTask(String taskId) async {
    try {
      await _client.cancelTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
