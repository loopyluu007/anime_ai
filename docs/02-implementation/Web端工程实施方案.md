# Web 端工程实施方案

> **目标**: 将 Flutter 应用适配到 Web 平台  
> **技术栈**: Flutter Web 3.0+  
> **版本**: v1.0

---

## 📋 目录

1. [项目初始化](#项目初始化)
2. [目录结构](#目录结构)
3. [Web 适配层](#web-适配层)
4. [API 客户端实现](#api-客户端实现)
5. [功能模块实现](#功能模块实现)
6. [响应式布局](#响应式布局)
7. [PWA 配置](#pwa-配置)
8. [构建和部署](#构建和部署)
9. [实施步骤](#实施步骤)

---

## 🚀 项目初始化

### 1. 创建 Web 项目

```bash
# 从现有项目创建 Web 分支，或创建新项目
flutter create web-app --platforms=web
cd web-app
```

### 2. 启用 Web 支持

```bash
flutter config --enable-web
flutter devices  # 应该能看到 Chrome 设备
```

### 3. 项目结构

```
web-app/
├── lib/
│   ├── main.dart
│   ├── core/              # 核心模块（与移动端共享部分）
│   ├── features/          # 功能模块（与移动端共享部分）
│   ├── shared/            # 共享模块（与移动端共享部分）
│   └── web/               # Web 特定代码
├── web/                   # Web 资源
├── test/
└── pubspec.yaml
```

---

## 📁 目录结构

### 完整目录结构

```
web-app/
├── lib/
│   ├── main.dart
│   │
│   ├── core/                      # 核心模块
│   │   ├── api/                   # API 客户端（共享）
│   │   │   ├── api_client.dart
│   │   │   ├── auth_client.dart
│   │   │   ├── conversation_client.dart
│   │   │   ├── task_client.dart
│   │   │   ├── screenplay_client.dart
│   │   │   └── media_client.dart
│   │   ├── storage/               # Web 存储适配
│   │   │   ├── web_storage_adapter.dart
│   │   │   └── indexed_db_adapter.dart
│   │   ├── cache/                 # 缓存管理
│   │   │   └── web_cache_manager.dart
│   │   ├── config/                # 配置（共享）
│   │   │   ├── app_config.dart
│   │   │   └── api_config.dart
│   │   └── utils/                 # 工具类（共享）
│   │       ├── logger.dart
│   │       └── validators.dart
│   │
│   ├── features/                  # 功能模块（与移动端共享）
│   │   ├── auth/                  # 认证功能
│   │   │   ├── screens/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── models/
│   │   │       └── user.dart
│   │   │
│   │   ├── chat/                  # 聊天功能
│   │   │   ├── screens/
│   │   │   │   ├── chat_screen.dart
│   │   │   │   └── conversation_list_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── message_bubble.dart
│   │   │   │   ├── message_input.dart
│   │   │   │   └── screenplay_card.dart
│   │   │   ├── providers/
│   │   │   │   ├── chat_provider.dart
│   │   │   │   └── conversation_provider.dart
│   │   │   └── models/
│   │   │       ├── message.dart
│   │   │       └── conversation.dart
│   │   │
│   │   ├── screenplay/            # 剧本功能
│   │   │   ├── screens/
│   │   │   │   ├── screenplay_review_screen.dart
│   │   │   │   └── screenplay_detail_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── scene_card.dart
│   │   │   │   ├── character_sheet_card.dart
│   │   │   │   └── progress_indicator.dart
│   │   │   ├── providers/
│   │   │   │   ├── screenplay_provider.dart
│   │   │   │   └── task_provider.dart
│   │   │   └── models/
│   │   │       ├── screenplay.dart
│   │   │       ├── scene.dart
│   │   │       └── character_sheet.dart
│   │   │
│   │   └── settings/              # 设置功能
│   │       ├── screens/
│   │       │   └── settings_screen.dart
│   │       └── providers/
│   │           └── settings_provider.dart
│   │
│   ├── shared/                    # 共享模块（与移动端共享）
│   │   ├── widgets/               # 通用组件
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   └── empty_state.dart
│   │   ├── utils/                 # 工具类
│   │   │   ├── date_utils.dart
│   │   │   └── string_utils.dart
│   │   └── themes/                # 主题
│   │       ├── app_theme.dart
│   │       └── colors.dart
│   │
│   └── web/                       # Web 特定代码
│       ├── adapters/              # Web 适配器
│       │   ├── storage_adapter.dart
│       │   ├── video_adapter.dart
│       │   ├── file_adapter.dart
│       │   └── image_picker_adapter.dart
│       ├── utils/                 # Web 工具
│       │   ├── pwa_utils.dart
│       │   └── seo_utils.dart
│       └── widgets/               # Web 特定组件
│           ├── responsive_layout.dart
│           └── web_video_player.dart
│
├── web/                           # Web 资源
│   ├── index.html
│   ├── manifest.json
│   ├── favicon.png
│   ├── icons/                     # PWA 图标
│   │   ├── icon-192.png
│   │   └── icon-512.png
│   └── assets/                    # 静态资源
│
├── test/                          # 测试
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── pubspec.yaml
├── .gitignore
└── README.md
```

---

## 🔧 Web 适配层

### 1. 存储适配器

#### `lib/web/adapters/storage_adapter.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

/// Web 存储适配器
class WebStorageAdapter {
  static SharedPreferences? _prefs;

  /// 初始化存储
  static Future<void> initialize() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// 保存字符串
  static Future<bool> setString(String key, String value) async {
    if (kIsWeb) {
      await initialize();
      return await _prefs?.setString(key, value) ?? false;
    }
    return false;
  }

  /// 获取字符串
  static Future<String?> getString(String key) async {
    if (kIsWeb) {
      await initialize();
      return _prefs?.getString(key);
    }
    return null;
  }

  /// 删除键
  static Future<bool> remove(String key) async {
    if (kIsWeb) {
      await initialize();
      return await _prefs?.remove(key) ?? false;
    }
    return false;
  }

  /// 清空所有
  static Future<bool> clear() async {
    if (kIsWeb) {
      await initialize();
      return await _prefs?.clear() ?? false;
    }
    return false;
  }
}
```

### 2. Hive Web 适配器

#### `lib/web/adapters/hive_web_adapter.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';

/// Hive Web 适配器
class HiveWebAdapter {
  /// 初始化 Hive（Web 端）
  static Future<void> initialize() async {
    if (kIsWeb) {
      // Web 端：直接初始化，使用 IndexedDB
      await Hive.initFlutter();
    } else {
      // 移动端：使用路径初始化（这里不会执行，但保留兼容性）
      throw UnsupportedError('移动端应使用 path_provider');
    }
  }

  /// 打开 Box
  static Future<Box<T>> openBox<T>(String name) async {
    await initialize();
    return await Hive.openBox<T>(name);
  }
}
```

### 3. 视频播放器适配器

#### `lib/web/adapters/video_adapter.dart`

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Web 视频播放器适配器
class WebVideoAdapter {
  /// 创建视频控制器（Web 端）
  static Future<VideoPlayerController> createController({
    required String dataSource,
    VideoPlayerOptions? options,
  }) async {
    if (kIsWeb) {
      // Web 端：只能使用网络 URL
      if (!dataSource.startsWith('http')) {
        throw ArgumentError('Web 端只支持网络 URL');
      }
      return VideoPlayerController.networkUrl(
        Uri.parse(dataSource),
        videoPlayerOptions: options,
      );
    } else {
      throw UnsupportedError('移动端应使用其他适配器');
    }
  }

  /// 构建 Web 视频播放器 Widget
  static Widget buildPlayer(VideoPlayerController controller) {
    if (kIsWeb) {
      return _WebVideoPlayer(controller: controller);
    }
    throw UnsupportedError('移动端应使用其他播放器');
  }
}

/// Web 视频播放器组件
class _WebVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _WebVideoPlayer({required this.controller});

  @override
  State<_WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<_WebVideoPlayer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await widget.controller.initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: widget.controller.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(widget.controller),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          if (widget.controller.value.isPlaying) {
            widget.controller.pause();
          } else {
            widget.controller.play();
          }
          setState(() {});
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: Icon(
              widget.controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}
```

### 4. 文件上传适配器

#### `lib/web/adapters/file_adapter.dart`

```dart
import 'dart:html' as html;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web 文件适配器
class WebFileAdapter {
  /// 选择图片（Web 端）
  static Future<XFile?> pickImage() async {
    if (!kIsWeb) {
      throw UnsupportedError('仅支持 Web 平台');
    }

    final completer = Completer<XFile?>();
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is String) {
          // 提取 base64 数据
          final base64 = result.split(',')[1];
          final bytes = base64Decode(base64);

          completer.complete(XFile.fromData(
            bytes,
            mimeType: file.type,
            name: file.name,
          ));
        } else {
          completer.complete(null);
        }
      });

      reader.readAsDataUrl(file);
    });

    return completer.future;
  }

  /// 下载文件（Web 端）
  static Future<void> downloadFile(String url, String filename) async {
    if (!kIsWeb) {
      throw UnsupportedError('仅支持 Web 平台');
    }

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
  }
}
```

---

## 🔌 API 客户端实现

### 1. API 客户端基类

#### `lib/core/api/api_client.dart`

```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../config/api_config.dart';
import 'auth_client.dart';

/// API 客户端基类
class ApiClient {
  late Dio _dio;
  final AuthClient _authClient;

  ApiClient(this._authClient) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加请求拦截器（添加 Token）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authClient.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // 处理 401 错误（Token 过期）
        if (error.response?.statusCode == 401) {
          _authClient.logout();
        }
        return handler.next(error);
      },
    ));

    // 添加日志拦截器（开发环境）
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        return ApiException(
          code: data['code'] ?? error.response!.statusCode,
          message: data['message'] ?? '请求失败',
          error: data['error'],
        );
      } else {
        return ApiException(
          code: 0,
          message: error.message ?? '网络错误',
        );
      }
    }
    return ApiException(code: 0, message: error.toString());
  }
}

/// API 异常
class ApiException implements Exception {
  final int code;
  final String message;
  final dynamic error;

  ApiException({
    required this.code,
    required this.message,
    this.error,
  });

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}
```

### 2. 认证客户端

#### `lib/core/api/auth_client.dart`

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/user.dart';

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
```

### 3. 对话客户端

#### `lib/core/api/conversation_client.dart`

```dart
import 'api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// 对话客户端
class ConversationClient {
  final ApiClient _apiClient;

  ConversationClient(this._apiClient);

  /// 创建对话
  Future<Conversation> createConversation(String title) async {
    final response = await _apiClient.post(
      '/conversations',
      data: {'title': title},
    );
    return Conversation.fromJson(response.data['data']);
  }

  /// 获取对话列表
  Future<PaginatedResponse<Conversation>> getConversations({
    int page = 1,
    int pageSize = 20,
    bool? pinned,
  }) async {
    final response = await _apiClient.get(
      '/conversations',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (pinned != null) 'pinned': pinned,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'],
      (json) => Conversation.fromJson(json),
    );
  }

  /// 获取对话详情
  Future<Conversation> getConversation(String id) async {
    final response = await _apiClient.get('/conversations/$id');
    return Conversation.fromJson(response.data['data']);
  }

  /// 更新对话
  Future<Conversation> updateConversation(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      '/conversations/$id',
      data: data,
    );
    return Conversation.fromJson(response.data['data']);
  }

  /// 删除对话
  Future<void> deleteConversation(String id) async {
    await _apiClient.delete('/conversations/$id');
  }

  /// 获取消息列表
  Future<PaginatedResponse<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get(
      '/conversations/$conversationId/messages',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'],
      (json) => Message.fromJson(json),
    );
  }
}

/// 分页响应
class PaginatedResponse<T> {
  final int page;
  final int pageSize;
  final int total;
  final List<T> items;

  PaginatedResponse({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse<T>(
      page: json['page'],
      pageSize: json['pageSize'],
      total: json['total'],
      items: (json['items'] as List)
          .map((item) => fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
```

### 4. 任务客户端

#### `lib/core/api/task_client.dart`

```dart
import 'api_client.dart';
import '../models/task.dart';

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
  }) async {
    final response = await _apiClient.get(
      '/tasks',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
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
}
```

---

## 📱 响应式布局

### `lib/web/widgets/responsive_layout.dart`

```dart
import 'package:flutter/material.dart';

/// 响应式布局工具
class ResponsiveLayout {
  /// 断点定义
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// 判断是否为移动端
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// 判断是否为平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// 判断是否为桌面端
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// 根据屏幕大小返回不同的值
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// 响应式列数
  static int responsiveColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }
}

/// 响应式容器
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.maxWidth = 1200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 1200,
        ),
        child: child,
      ),
    );
  }
}
```

---

## 📱 PWA 配置

### `web/manifest.json`

```json
{
  "name": "AI漫导",
  "short_name": "AI漫导",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#8B5CF6",
  "orientation": "portrait-primary",
  "icons": [
    {
      "src": "icons/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "icons/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ]
}
```

### `web/index.html`

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="AI漫导 - AI 智能体驱动的短剧制作平台">
  <title>AI漫导</title>
  
  <!-- PWA -->
  <link rel="manifest" href="manifest.json">
  <meta name="theme-color" content="#8B5CF6">
  
  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png">
  
  <!-- Flutter Web -->
  <script src="main.dart.js" type="application/javascript"></script>
</head>
<body>
  <script>
    window.addEventListener('load', function(ev) {
      _flutter.loader.loadEntrypoint({
        serviceWorker: {
          serviceWorkerVersion: serviceWorkerVersion,
        },
        onEntrypointLoaded: function(engineInitializer) {
          engineInitializer.initializeEngine().then(function(appRunner) {
            appRunner.runApp();
          });
        }
      });
    });
  </script>
</body>
</html>
```

---

## 🚀 构建和部署

### 1. 构建 Web 应用

```bash
# 构建生产版本
flutter build web --release

# 构建输出目录
# build/web/
```

### 2. 部署到 Nginx

#### `nginx.conf` 示例

```nginx
server {
    listen 80;
    server_name directorai.com;
    
    root /var/www/directorai/web;
    index index.html;
    
    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # SPA 路由支持
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    # API 代理
    location /api/ {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 📝 实施步骤

### 阶段一：项目初始化（第1周）

1. **创建 Web 项目**
   ```bash
   flutter create web-app --platforms=web
   cd web-app
   ```

2. **配置依赖**
   ```yaml
   # pubspec.yaml
   dependencies:
     flutter:
       sdk: flutter
     dio: ^5.4.0
     provider: ^6.1.1
     shared_preferences: ^2.2.2
     hive: ^2.2.3
     hive_flutter: ^1.1.0
     video_player: ^2.8.2
     cached_network_image: ^3.3.1
   ```

3. **创建目录结构**
   ```bash
   mkdir -p lib/{core/{api,storage,cache,config,utils},features/{auth,chat,screenplay,settings},shared/{widgets,utils,themes},web/{adapters,utils,widgets}}
   ```

### 阶段二：Web 适配层（第2周）

1. **实现存储适配器**
   - WebStorageAdapter
   - HiveWebAdapter

2. **实现视频适配器**
   - WebVideoAdapter
   - WebVideoPlayer

3. **实现文件适配器**
   - WebFileAdapter
   - 图片选择
   - 文件下载

### 阶段三：API 客户端（第3周）

1. **实现 API 客户端基类**
   - ApiClient
   - 错误处理
   - Token 管理

2. **实现各功能客户端**
   - AuthClient
   - ConversationClient
   - TaskClient
   - ScreenplayClient
   - MediaClient

### 阶段四：功能模块（第4周）

1. **实现认证功能**
   - 登录页面
   - 注册页面
   - AuthProvider

2. **实现聊天功能**
   - 聊天界面
   - 对话列表
   - ChatProvider

3. **实现剧本功能**
   - 剧本预览
   - 剧本详情
   - ScreenplayProvider

### 阶段五：响应式和优化（第5周）

1. **实现响应式布局**
   - ResponsiveLayout
   - 适配不同屏幕

2. **配置 PWA**
   - manifest.json
   - Service Worker
   - 离线支持

3. **性能优化**
   - 代码分割
   - 懒加载
   - 图片优化

### 阶段六：测试和部署（第6周）

1. **测试**
   - 功能测试
   - 浏览器兼容性测试
   - 响应式测试

2. **部署**
   - 构建生产版本
   - 配置 Nginx
   - 部署到服务器

---

## 🔧 开发工具和命令

### 开发命令

```bash
# 运行 Web 应用（开发模式）
flutter run -d chrome

# 构建 Web 应用
flutter build web

# 分析代码
flutter analyze

# 运行测试
flutter test
```

### 调试技巧

```dart
// Web 端调试
import 'dart:html' as html;

void debugPrint(String message) {
  if (kDebugMode) {
    html.window.console.log(message);
  }
}
```

---

**文档版本**: v1.0  
**最后更新**: 2026-01-12
