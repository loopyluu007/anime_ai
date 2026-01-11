import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../storage/local_storage.dart';
import '../utils/logger.dart';

/// WebSocket 连接状态
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket 消息类型
enum WebSocketMessageType {
  ping,
  pong,
  taskProgress,
  taskCompleted,
  taskFailed,
  messageNew,
  subscribe,
  unsubscribe,
  error,
}

/// WebSocket 客户端
class WebSocketClient {
  static const String _tokenKey = 'auth_token';
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const int _maxReconnectAttempts = 5;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _shouldReconnect = true;
  final Future<String?> Function()? _getToken;

  // 订阅的频道
  final Set<String> _subscribedChannels = {};

  // 回调函数
  Function(WebSocketMessageType type, Map<String, dynamic> data)? onMessage;
  Function(WebSocketStatus status)? onStatusChanged;
  Function(String error)? onError;

  WebSocketClient({Future<String?> Function()? getToken})
      : _getToken = getToken;

  /// 当前连接状态
  WebSocketStatus get status => _status;

  /// 是否已连接
  bool get isConnected => _status == WebSocketStatus.connected;

  /// 是否正在连接
  bool get isConnecting =>
      _status == WebSocketStatus.connecting ||
      _status == WebSocketStatus.reconnecting;

  /// 连接 WebSocket
  Future<void> connect() async {
    if (isConnecting || isConnected) {
      Logger.warning('WebSocket 已连接或正在连接中');
      return;
    }

    _shouldReconnect = true;
    await _doConnect();
  }

  /// 执行连接
  Future<void> _doConnect() async {
    try {
      _updateStatus(WebSocketStatus.connecting);

      // 获取 Token
      String? token;
      if (_getToken != null) {
        token = await _getToken();
      } else {
        token = await LocalStorage.getString(_tokenKey);
      }

      if (token == null || token.isEmpty) {
        throw Exception('Token 未找到，无法连接 WebSocket');
      }

      // 构建 WebSocket URL
      String wsUrl = ApiConfig.wsUrl;
      // 确保使用正确的协议
      if (wsUrl.startsWith('http://')) {
        wsUrl = wsUrl.replaceFirst('http://', 'ws://');
      } else if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceFirst('https://', 'wss://');
      } else if (!wsUrl.startsWith('ws://') && !wsUrl.startsWith('wss://')) {
        // 如果没有协议，默认使用 ws://
        wsUrl = 'ws://$wsUrl';
      }
      final uri = Uri.parse('$wsUrl?token=$token');

      Logger.info('正在连接 WebSocket: $uri');

      // 创建 WebSocket 连接
      _channel = WebSocketChannel.connect(uri);

      _reconnectAttempts = 0;
      _updateStatus(WebSocketStatus.connected);

      // 开始监听消息
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // 启动心跳
      _startHeartbeat();

      // 重新订阅之前的频道
      _resubscribeChannels();

      Logger.info('WebSocket 连接成功');
    } catch (e) {
      Logger.error('WebSocket 连接失败: $e');
      _updateStatus(WebSocketStatus.error);
      onError?.call(e.toString());

      // 尝试重连
      if (_shouldReconnect) {
        _scheduleReconnect();
      }
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _stopHeartbeat();
    _cancelReconnect();

    await _subscription?.cancel();
    _subscription = null;

    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (e) {
        Logger.error('关闭 WebSocket 连接失败: $e');
      }
      _channel = null;
    }

    _updateStatus(WebSocketStatus.disconnected);
    Logger.info('WebSocket 已断开连接');
  }

  /// 发送消息
  void send(Map<String, dynamic> message) {
    if (!isConnected || _channel == null) {
      Logger.warning('WebSocket 未连接，无法发送消息');
      return;
    }

    try {
      final json = jsonEncode(message);
      _channel!.sink.add(json);
      Logger.debug('发送 WebSocket 消息: $json');
    } catch (e) {
      Logger.error('发送 WebSocket 消息失败: $e');
      onError?.call('发送消息失败: $e');
    }
  }

  /// 订阅频道
  void subscribe(String channel, {String? taskId, String? conversationId}) {
    if (!isConnected) {
      Logger.warn('WebSocket 未连接，无法订阅频道');
      return;
    }

    final channelKey = _getChannelKey(channel, taskId: taskId, conversationId: conversationId);
    if (_subscribedChannels.contains(channelKey)) {
      Logger.debug('频道已订阅: $channelKey');
      return;
    }

    final message = {
      'type': 'subscribe',
      'channel': channel,
      if (taskId != null) 'taskId': taskId,
      if (conversationId != null) 'conversationId': conversationId,
    };

    send(message);
    _subscribedChannels.add(channelKey);
    Logger.info('订阅频道: $channelKey');
  }

  /// 取消订阅频道
  void unsubscribe(String channel, {String? taskId, String? conversationId}) {
    if (!isConnected) {
      return;
    }

    final channelKey = _getChannelKey(channel, taskId: taskId, conversationId: conversationId);
    if (!_subscribedChannels.contains(channelKey)) {
      return;
    }

    final message = {
      'type': 'unsubscribe',
      'channel': channel,
      if (taskId != null) 'taskId': taskId,
      if (conversationId != null) 'conversationId': conversationId,
    };

    send(message);
    _subscribedChannels.remove(channelKey);
    Logger.info('取消订阅频道: $channelKey');
  }

  /// 处理接收到的消息
  void _handleMessage(dynamic data) {
    try {
      String messageStr;
      if (data is String) {
        messageStr = data;
      } else {
        messageStr = data.toString();
      }
      
      final message = jsonDecode(messageStr) as Map<String, dynamic>;
      final typeStr = message['type'] as String?;

      if (typeStr == null) {
        Logger.warning('收到无效的 WebSocket 消息: $message');
        return;
      }

      // 处理心跳
      if (typeStr == 'pong') {
        Logger.debug('收到心跳响应');
        return;
      }

      // 解析消息类型
      final messageType = _parseMessageType(typeStr);
      final messageData = message['data'] as Map<String, dynamic>? ?? {};

      // 添加额外信息
      if (message.containsKey('taskId')) {
        messageData['taskId'] = message['taskId'];
      }
      if (message.containsKey('conversationId')) {
        messageData['conversationId'] = message['conversationId'];
      }

      Logger.debug('收到 WebSocket 消息: type=$typeStr, data=$messageData');

      // 触发回调
      onMessage?.call(messageType, messageData);
    } catch (e) {
      Logger.error('处理 WebSocket 消息失败: $e');
      onError?.call('处理消息失败: $e');
    }
  }

  /// 处理错误
  void _handleError(dynamic error) {
    Logger.error('WebSocket 错误: $error');
    _updateStatus(WebSocketStatus.error);
    onError?.call(error.toString());

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// 处理断开连接
  void _handleDisconnect() {
    Logger.warning('WebSocket 连接已断开');
    _stopHeartbeat();
    _subscription = null;
    _channel = null;

    if (_shouldReconnect) {
      _updateStatus(WebSocketStatus.reconnecting);
      _scheduleReconnect();
    } else {
      _updateStatus(WebSocketStatus.disconnected);
    }
  }

  /// 更新状态
  void _updateStatus(WebSocketStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      onStatusChanged?.call(newStatus);
    }
  }

  /// 启动心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        send({'type': 'ping'});
      } else {
        _stopHeartbeat();
      }
    });
  }

  /// 停止心跳
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 安排重连
  void _scheduleReconnect() {
    _cancelReconnect();

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      Logger.error('WebSocket 重连次数已达上限');
      _updateStatus(WebSocketStatus.error);
      onError?.call('连接失败，已达到最大重连次数');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      milliseconds: _reconnectDelay.inMilliseconds * _reconnectAttempts,
    );

    Logger.info('将在 ${delay.inSeconds} 秒后尝试重连 (${_reconnectAttempts}/$_maxReconnectAttempts)');

    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect) {
        _doConnect();
      }
    });
  }

  /// 取消重连
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 重新订阅频道
  void _resubscribeChannels() {
    // 清空订阅列表，让调用者重新订阅
    _subscribedChannels.clear();
  }

  /// 获取频道键
  String _getChannelKey(String channel, {String? taskId, String? conversationId}) {
    if (taskId != null) {
      return '$channel:$taskId';
    }
    if (conversationId != null) {
      return '$channel:$conversationId';
    }
    return channel;
  }

  /// 解析消息类型
  WebSocketMessageType _parseMessageType(String type) {
    switch (type) {
      case 'ping':
        return WebSocketMessageType.ping;
      case 'pong':
        return WebSocketMessageType.pong;
      case 'task.progress':
        return WebSocketMessageType.taskProgress;
      case 'task.completed':
        return WebSocketMessageType.taskCompleted;
      case 'task.failed':
        return WebSocketMessageType.taskFailed;
      case 'message.new':
        return WebSocketMessageType.messageNew;
      case 'error':
        return WebSocketMessageType.error;
      default:
        return WebSocketMessageType.error;
    }
  }

  /// 释放资源
  void dispose() {
    disconnect();
  }
}
