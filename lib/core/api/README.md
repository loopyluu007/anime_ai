# API 客户端模块

本模块提供了与后端 API 交互的完整客户端实现。

## 模块结构

```
lib/core/api/
├── api_client.dart          # API 客户端基类
├── auth_client.dart         # 认证客户端
├── conversation_client.dart # 对话客户端
├── task_client.dart         # 任务客户端
├── screenplay_client.dart   # 剧本客户端
├── media_client.dart        # 媒体客户端
└── api.dart                 # 导出文件
```

## 使用示例

### 1. 初始化 API 客户端

```dart
import 'package:director_ai/core/api/api.dart';
import 'package:director_ai/core/config/api_config.dart';

// 创建认证客户端（需要先创建）
final authClient = AuthClient(apiClient);
final apiClient = ApiClient(authClient);

// 创建其他客户端
final conversationClient = ConversationClient(apiClient);
final taskClient = TaskClient(apiClient);
final screenplayClient = ScreenplayClient(apiClient);
final mediaClient = MediaClient(apiClient);
```

### 2. 认证功能

```dart
// 登录
final user = await authClient.login('email@example.com', 'password123');

// 注册
final newUser = await authClient.register(
  'username',
  'email@example.com',
  'password123',
);

// 获取当前用户
final currentUser = await authClient.getCurrentUser();

// 检查登录状态
final isLoggedIn = await authClient.isLoggedIn();

// 登出
await authClient.logout();
```

### 3. 对话管理

```dart
// 创建对话
final conversation = await conversationClient.createConversation('新对话');

// 获取对话列表
final conversations = await conversationClient.getConversations(
  page: 1,
  pageSize: 20,
  pinned: true, // 可选：只获取置顶对话
);

// 获取对话详情
final detail = await conversationClient.getConversation(conversation.id);

// 更新对话
final updated = await conversationClient.updateConversation(
  conversation.id,
  {'title': '新标题', 'isPinned': true},
);

// 获取消息列表
final messages = await conversationClient.getMessages(
  conversation.id,
  page: 1,
  pageSize: 50,
);

// 删除对话
await conversationClient.deleteConversation(conversation.id);
```

### 4. 任务管理

```dart
// 创建任务
final task = await taskClient.createTask(
  TaskCreateRequest(
    type: TaskType.screenplay,
    conversationId: conversation.id,
    params: {
      'prompt': '生成一个雪地里的冒险故事',
      'sceneCount': 7,
    },
  ),
);

// 获取任务列表
final tasks = await taskClient.getTasks(
  page: 1,
  pageSize: 20,
  type: TaskType.screenplay, // 可选
  status: TaskStatus.processing, // 可选
);

// 获取任务详情
final taskDetail = await taskClient.getTask(task.id);

// 获取任务进度
final progress = await taskClient.getTaskProgress(task.id);

// 取消任务
await taskClient.cancelTask(task.id);

// 删除任务
await taskClient.deleteTask(task.id);
```

### 5. 剧本管理

```dart
// 生成剧本草稿
final screenplay = await screenplayClient.createDraft(
  ScreenplayDraftRequest(
    taskId: task.id,
    prompt: '生成一个雪地里的冒险故事',
    sceneCount: 7,
    characterCount: 2,
  ),
);

// 确认剧本
final confirmed = await screenplayClient.confirmScreenplay(
  screenplay.id,
  ScreenplayConfirmRequest(
    feedback: '请增加一些动作场景',
  ),
);

// 获取剧本详情
final detail = await screenplayClient.getScreenplay(screenplay.id);

// 更新剧本
final updated = await screenplayClient.updateScreenplay(
  screenplay.id,
  {'title': '新标题'},
);
```

### 6. 媒体服务

```dart
// 上传图片
final imageInfo = await mediaClient.uploadImage(
  '/path/to/image.jpg',
  type: MediaType.reference,
);

// 生成图片（异步）
final imageTask = await mediaClient.generateImage(
  prompt: 'A beautiful landscape',
  model: 'gemini-3-pro-image-preview-hd',
  size: '1024x1024',
  referenceImages: ['image_id1', 'image_id2'],
);

// 获取生成的图片
final generatedImage = await mediaClient.getImage(imageInfo.id);

// 生成视频（异步）
final videoTask = await mediaClient.generateVideo(
  imageId: imageInfo.id,
  prompt: 'The scene is animated...',
  model: 'sora-1',
  seconds: 10,
);

// 获取生成的视频
final video = await mediaClient.getVideo(videoTask.id);

// 合并视频
final mergeTask = await mediaClient.mergeVideos(
  videoIds: ['video_id1', 'video_id2', 'video_id3'],
  title: '合并后的视频',
);

// 获取合并进度
final mergeProgress = await mediaClient.getMergeProgress(mergeTask.id);
```

## 错误处理

所有 API 调用都可能抛出 `ApiException`，需要适当处理：

```dart
try {
  final user = await authClient.login('email@example.com', 'password');
} on ApiException catch (e) {
  print('API 错误: ${e.code} - ${e.message}');
  // 处理错误
} catch (e) {
  print('其他错误: $e');
}
```

## 配置

API 配置在 `lib/core/config/api_config.dart` 中：

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8001/api/v1';
  static const String wsUrl = 'ws://localhost:8001/ws';
  // ...
}
```

## 注意事项

1. **Token 管理**: `AuthClient` 自动管理 Token，在请求时自动添加到请求头
2. **401 错误**: 当收到 401 错误时，`ApiClient` 会自动调用 `logout()` 清除本地 Token
3. **分页**: 所有列表接口都支持分页，返回 `PaginatedResponse<T>` 对象
4. **异步任务**: 图片和视频生成是异步的，返回任务对象，需要通过 `TaskClient` 查询进度
