/// API配置
class ApiConfig {
  /// API基础URL
  static const String baseUrl = 'http://localhost:8001/api/v1';
  
  /// WebSocket URL
  static const String wsUrl = 'ws://localhost:8001/ws';
  
  /// 请求超时时间（秒）
  static const int connectTimeout = 30;
  
  /// 接收超时时间（秒）
  static const int receiveTimeout = 60;
}
