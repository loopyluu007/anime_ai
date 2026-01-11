# WebSocket 实时通信模块使用指南

## 📋 概述

WebSocket 实时通信模块为 Chat 模块提供实时消息推送功能，支持：
- 实时接收新消息
- 任务进度更新
- 自动重连机制
- 心跳保活

## 🚀 快速开始

### 1. 基本配置

WebSocket Provider 已在 `main.dart` 中配置，会在用户登录后自动连接。

### 2. 在 ChatScreen 中使用

```dart
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/websocket_provider.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    
    // 获取 WebSocket Provider 并订阅对话
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // 设置 WebSocket Provider 到 ChatProvider
      chatProvider.setWebSocketProvider(wsProvider);
      
      // 订阅对话消息
      wsProvider.subscribeConversation(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    // 取消订阅
    final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
    wsProvider.unsubscribeConversation(widget.conversation.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... UI 代码
  }
}
```

### 3. 监听连接状态

```dart
Consumer<WebSocketProvider>(
  builder: (context, provider, child) {
    final status = provider.status;
    
    if (status == WebSocketStatus.connected) {
      return Icon(Icons.cloud_done, color: Colors.green);
    } else if (status == WebSocketStatus.connecting) {
      return CircularProgressIndicator();
    } else {
      return Icon(Icons.cloud_off, color: Colors.red);
    }
  },
)
```

## 📡 订阅频道

### 订阅对话消息

```dart
final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
wsProvider.subscribeConversation('conversation_id');
```

### 订阅任务进度

```dart
final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
wsProvider.subscribeTask('task_id');
```

### 取消订阅

```dart
// 取消订阅对话
wsProvider.unsubscribeConversation('conversation_id');

// 取消订阅任务
wsProvider.unsubscribeTask('task_id');
```

## 🔔 消息处理

WebSocket Provider 会自动处理以下消息类型：

### 1. 新消息 (`message.new`)

当收到新消息时，会自动：
- 如果当前对话是接收消息的对话，则添加到消息列表
- 更新对话列表（刷新预览文本等）

### 2. 任务进度 (`task.progress`)

```dart
// 在 WebSocketProvider 中处理
void _handleTaskProgress(Map<String, dynamic> data) {
  final taskId = data['taskId'] as String?;
  final progress = data['progress'] as int?;
  final status = data['status'] as String?;
  
  // 更新任务进度
  // taskProvider.updateProgress(taskId, progress, status);
}
```

### 3. 任务完成 (`task.completed`)

```dart
void _handleTaskCompleted(Map<String, dynamic> data) {
  final taskId = data['taskId'] as String?;
  final result = data['result'] as Map<String, dynamic>?;
  
  // 处理任务完成
}
```

### 4. 任务失败 (`task.failed`)

```dart
void _handleTaskFailed(Map<String, dynamic> data) {
  final taskId = data['taskId'] as String?;
  final error = data['error'] as String?;
  
  // 处理任务失败
}
```

## 🔧 高级用法

### 手动连接/断开

```dart
final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);

// 连接
await wsProvider.initialize();

// 断开
await wsProvider.disconnect();
```

### 监听连接状态变化

```dart
Consumer<WebSocketProvider>(
  builder: (context, provider, child) {
    final status = provider.status;
    
    switch (status) {
      case WebSocketStatus.connected:
        // 已连接
        break;
      case WebSocketStatus.connecting:
        // 连接中
        break;
      case WebSocketStatus.reconnecting:
        // 重连中
        break;
      case WebSocketStatus.disconnected:
        // 已断开
        break;
      case WebSocketStatus.error:
        // 错误
        break;
    }
    
    return YourWidget();
  },
)
```

## 🐛 故障排除

### 1. WebSocket 无法连接

**检查项：**
- Token 是否有效
- API 配置是否正确（`ApiConfig.wsUrl`）
- 网络连接是否正常
- 后端服务是否运行

### 2. 消息未收到

**检查项：**
- 是否已订阅对应频道
- 消息格式是否正确
- 查看控制台日志

### 3. 自动重连失败

**检查项：**
- Token 是否过期
- 网络是否稳定
- 查看重连日志

## 📝 注意事项

1. **Token 管理**：WebSocket 连接需要有效的 Token，Token 过期后需要重新连接
2. **资源清理**：在页面销毁时记得取消订阅，避免内存泄漏
3. **错误处理**：建议监听 `onError` 回调，处理连接错误
4. **性能优化**：避免频繁订阅/取消订阅，合理管理订阅生命周期

## 🔗 相关文档

- [API接口设计文档 - WebSocket](../../../docs/03-api-database/API接口设计文档.md#websocket-实时通信)
- [Chat 模块 README](./README.md)
- [Chat 模块实现总结](./IMPLEMENTATION.md)
