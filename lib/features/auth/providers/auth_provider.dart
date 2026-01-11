import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/auth_client.dart';
import 'package:dio/dio.dart';

/// 认证状态
enum AuthStatus {
  initial,    // 初始状态
  loading,    // 加载中
  authenticated, // 已认证
  unauthenticated, // 未认证
  error,      // 错误
}

/// 认证 Provider
class AuthProvider extends ChangeNotifier {
  final AuthClient _authClient;
  
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthProvider(this._authClient) {
    _checkAuthStatus();
  }

  /// 当前状态
  AuthStatus get status => _status;
  
  /// 当前用户
  User? get user => _user;
  
  /// 错误消息
  String? get errorMessage => _errorMessage;
  
  /// 是否已认证
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  
  /// 是否加载中
  bool get isLoading => _status == AuthStatus.loading;

  /// 检查认证状态
  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await _authClient.isLoggedIn();
      if (isLoggedIn) {
        await _loadCurrentUser();
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// 加载当前用户
  Future<void> _loadCurrentUser() async {
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      _user = await _authClient.getCurrentUser();
      _status = AuthStatus.authenticated;
      _errorMessage = null;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = '获取用户信息失败: ${e.toString()}';
      await _authClient.logout();
    } finally {
      notifyListeners();
    }
  }

  /// 登录
  Future<bool> login(String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authClient.login(email, password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// 注册
  Future<bool> register(String username, String email, String password) async {
    try {
      _status = AuthStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _user = await _authClient.register(username, email, password);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _extractErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _authClient.logout();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = '登出失败: ${e.toString()}';
      notifyListeners();
    }
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    await _loadCurrentUser();
  }

  /// 提取错误消息
  String _extractErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    } else if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        return data['message'] ?? '请求失败';
      } else {
        return error.message ?? '网络错误';
      }
    }
    return error.toString();
  }
}
