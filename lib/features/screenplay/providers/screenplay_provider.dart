import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/screenplay_client.dart';
import '../models/screenplay.dart';
import '../models/screenplay_requests.dart';

class ScreenplayProvider extends ChangeNotifier {
  final ScreenplayClient _client;
  
  Screenplay? _currentScreenplay;
  bool _isLoading = false;
  String? _error;
  
  Screenplay? get currentScreenplay => _currentScreenplay;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  ScreenplayProvider(ScreenplayClient? client) 
      : _client = client ?? ScreenplayClient(ApiClient());
  
  /// 获取剧本详情
  Future<Screenplay> getScreenplay(String screenplayId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentScreenplay = await _client.getScreenplay(screenplayId);
      return _currentScreenplay!;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 确认剧本
  Future<Screenplay> confirmScreenplay(
    String screenplayId, {
    String? feedback,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentScreenplay = await _client.confirmScreenplay(
        screenplayId,
        feedback: feedback,
      );
      return _currentScreenplay!;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 更新剧本标题
  Future<Screenplay> updateScreenplayTitle(
    String screenplayId,
    String title,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentScreenplay = await _client.updateScreenplay(
        screenplayId,
        title: title,
      );
      return _currentScreenplay!;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 生成剧本草稿
  Future<Screenplay> createDraft(ScreenplayDraftRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentScreenplay = await _client.createDraft(request);
      return _currentScreenplay!;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// 清除当前剧本
  void clearCurrentScreenplay() {
    _currentScreenplay = null;
    notifyListeners();
  }
}
