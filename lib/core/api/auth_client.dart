import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../../features/auth/models/user.dart';

/// 认证客户端
class AuthClient {
  final ApiClient _apiClient;
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';

  AuthClient(this._apiClient);

  /// 登录
  Future<User> login(String email, String password) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = response.data['data'];
    await _saveTokens(
      data['token'],
      data['refreshToken'],
      data['userId'],
    );

    return User.fromJson(data);
  }

  /// 注册
  Future<User> register(String username, String email, String password) async {
    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'username': username,
        'email': email,
        'password': password,
      },
    );

    final data = response.data['data'];
    await _saveTokens(
      data['token'],
      data['refreshToken'],
      data['userId'],
    );

    return User.fromJson(data);
  }

  /// 刷新 Token
  Future<User> refreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      throw ApiException(code: 2002, message: 'Refresh token 不存在');
    }

    final response = await _apiClient.post(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );

    final data = response.data['data'];
    await _saveTokens(
      data['token'],
      data['refreshToken'],
      data['userId'],
    );

    return User.fromJson(data);
  }

  /// 获取当前用户
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get('/auth/me');
    return User.fromJson(response.data['data']);
  }

  /// 获取 Token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  /// 获取用户 ID
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// 保存 Tokens
  Future<void> _saveTokens(String token, String refreshToken, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userIdKey, userId);
  }

  /// 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userIdKey);
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
