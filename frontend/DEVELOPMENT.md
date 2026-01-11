# 前端开发施工文档

> **版本**: v1.1  
> **最后更新**: 2026-01-12  
> **维护者**: 开发团队

---

## 📋 目录

1. [项目概述](#项目概述)
2. [开发环境配置](#开发环境配置)
3. [项目结构](#项目结构)
4. [开发指南](#开发指南)
5. [功能模块实现状态](#功能模块实现状态)
6. [Web适配](#web适配)
7. [测试指南](#测试指南)
8. [常见问题](#常见问题)

---

## 🎯 项目概述

AI漫导前端应用基于Flutter框架开发，支持移动端（Android/iOS）和Web端。主要功能包括：

- **认证系统**: 用户注册、登录、Token管理
- **对话管理**: 创建对话、发送消息、查看历史
- **剧本生成**: 生成剧本草稿、确认剧本、查看详情
- **任务管理**: 创建任务、查看进度、任务状态
- **媒体展示**: 图片预览、视频播放、图库管理

### 技术栈

- **语言**: Dart 3.0+
- **框架**: Flutter 3.0+
- **状态管理**: Provider 6.1+
- **网络请求**: Dio 5.4+
- **本地存储**: Hive 2.2+ / SharedPreferences 2.2+
- **视频播放**: video_player 2.8+ / chewie 1.7+
- **图片缓存**: cached_network_image 3.3+

---

## 🛠️ 开发环境配置

### 1. 环境要求

```bash
Flutter >= 3.0.0
Dart >= 3.0.0
Android Studio / VS Code
Chrome (Web开发)
```

### 2. 项目初始化

```bash
# 1. 克隆项目（如果还没有）
git clone <repository-url>
cd anime_ai

# 2. 安装依赖
flutter pub get

# 3. 生成代码（如果有代码生成需求）
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 检查环境
flutter doctor
```

### 3. 环境变量配置

创建 `.env` 文件（参考 `.env.example`）：

```bash
# API配置
API_BASE_URL=http://localhost:8001/api/v1
WS_URL=ws://localhost:8001/ws

# 开发环境
DEBUG=true
```

或在代码中配置（`lib/core/config/api_config.dart`）：

```dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:8001/api/v1';
  static const String wsUrl = 'ws://localhost:8001/ws';
}
```

### 4. 启用Web支持（可选）

```bash
# 启用Web平台
flutter config --enable-web

# 检查可用设备
flutter devices
```

---

## 📁 项目结构

```
lib/
├── main.dart                 # 应用入口
│
├── core/                     # 核心模块
│   ├── api/                  # API客户端
│   │   ├── api_client.dart   # API基类
│   │   ├── auth_client.dart  # 认证客户端
│   │   ├── conversation_client.dart
│   │   ├── task_client.dart
│   │   ├── screenplay_client.dart
│   │   └── media_client.dart
│   ├── storage/              # 本地存储
│   │   ├── local_storage.dart
│   │   ├── cache_manager.dart
│   │   └── hive_service.dart
│   ├── cache/                # 缓存管理
│   │   ├── image_cache.dart
│   │   └── video_cache.dart
│   ├── config/               # 配置
│   │   ├── app_config.dart
│   │   └── api_config.dart
│   └── utils/                # 工具类
│       ├── logger.dart
│       ├── validators.dart
│       └── formatters.dart
│
├── features/                 # 功能模块
│   ├── auth/                 # 认证功能
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── providers/
│   │   │   └── auth_provider.dart
│   │   └── models/
│   │       └── user.dart
│   │
│   ├── chat/                 # 聊天功能
│   │   ├── screens/
│   │   │   ├── chat_screen.dart
│   │   │   └── conversation_list_screen.dart
│   │   ├── widgets/
│   │   │   ├── message_bubble.dart
│   │   │   ├── message_input.dart
│   │   │   └── screenplay_card.dart
│   │   ├── providers/
│   │   │   ├── chat_provider.dart
│   │   │   └── conversation_provider.dart
│   │   └── models/
│   │       ├── message.dart
│   │       └── conversation.dart
│   │
│   ├── screenplay/           # 剧本功能
│   │   ├── screens/
│   │   │   ├── screenplay_review_screen.dart
│   │   │   └── screenplay_detail_screen.dart
│   │   ├── widgets/
│   │   │   ├── scene_card.dart
│   │   │   ├── character_sheet_card.dart
│   │   │   └── progress_indicator.dart
│   │   ├── providers/
│   │   │   ├── screenplay_provider.dart
│   │   │   └── task_provider.dart
│   │   └── models/
│   │       ├── screenplay.dart
│   │       ├── scene.dart
│   │       └── character_sheet.dart
│   │
│   └── settings/             # 设置功能
│       ├── screens/
│       │   └── settings_screen.dart
│       └── providers/
│           └── settings_provider.dart
│
├── shared/                   # 共享模块
│   ├── widgets/              # 通用组件
│   │   ├── loading_indicator.dart
│   │   ├── error_widget.dart
│   │   ├── empty_state.dart
│   │   └── video_player.dart
│   ├── utils/                # 工具类
│   │   ├── date_utils.dart
│   │   ├── string_utils.dart
│   │   └── file_utils.dart
│   └── themes/               # 主题
│       ├── app_theme.dart
│       └── colors.dart
│
└── web/                      # Web特定代码（可选）
    ├── adapters/             # Web适配器
    │   ├── storage_adapter.dart
    │   ├── video_adapter.dart
    │   └── file_adapter.dart
    └── utils/                 # Web工具
        └── pwa_utils.dart

图例: ✅ 已完成 | ⏳ 部分完成 | ❌ 待实现
```

---

## 📝 开发指南

### 1. 添加新的API客户端

**步骤：**

1. 在 `lib/core/api/` 创建新的客户端文件
2. 继承或使用 `ApiClient` 基类
3. 实现具体的API方法

**示例：**

```dart
// lib/core/api/example_client.dart
import 'api_client.dart';

class ExampleClient {
  final ApiClient _apiClient;

  ExampleClient(this._apiClient);

  Future<ExampleModel> getExample(String id) async {
    final response = await _apiClient.get('/example/$id');
    return ExampleModel.fromJson(response.data['data']);
  }

  Future<ExampleModel> createExample(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/example', data: data);
    return ExampleModel.fromJson(response.data['data']);
  }
}
```

### 2. 添加新的功能模块

**步骤：**

1. 在 `lib/features/` 创建功能目录
2. 创建 `screens/`、`widgets/`、`providers/`、`models/` 子目录
3. 实现页面、组件、状态管理和数据模型
4. 在路由中注册页面

**示例：**

```dart
// lib/features/example/screens/example_screen.dart
class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('示例')),
      body: Consumer<ExampleProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return LoadingIndicator();
          }
          return ListView(
            children: provider.items.map((item) => 
              ListTile(title: Text(item.name))
            ).toList(),
          );
        },
      ),
    );
  }
}

// lib/features/example/providers/example_provider.dart
class ExampleProvider extends ChangeNotifier {
  final ExampleClient _client;
  List<ExampleModel> _items = [];
  bool _isLoading = false;

  List<ExampleModel> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    try {
      _items = await _client.getItems();
    } catch (e) {
      // 错误处理
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 3. 添加新的数据模型

**步骤：**

1. 在对应的 `features/*/models/` 目录创建模型文件
2. 实现 `fromJson` 和 `toJson` 方法
3. 如需要持久化，添加Hive适配器

**示例：**

```dart
// lib/features/example/models/example_model.dart
class ExampleModel {
  final String id;
  final String name;
  final DateTime createdAt;

  ExampleModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory ExampleModel.fromJson(Map<String, dynamic> json) {
    return ExampleModel(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
```

### 4. 添加Web适配器（Web端）

**步骤：**

1. 在 `lib/web/adapters/` 创建适配器文件
2. 使用条件导入分离平台代码
3. 实现Web特定功能

**示例：**

```dart
// lib/web/adapters/example_adapter.dart
import 'package:flutter/foundation.dart' show kIsWeb;

class ExampleAdapter {
  static Future<void> doSomething() async {
    if (kIsWeb) {
      // Web特定实现
      // 使用 dart:html
    } else {
      // 移动端实现
      // 使用平台通道
    }
  }
}
```

---

## 🔌 功能模块实现状态

### API 客户端模块

| 功能 | 状态 | 说明 |
|------|------|------|
| API客户端基类 | ✅ | 已完成 - ApiClient |
| 认证客户端 | ✅ | 已完成 - AuthClient |
| 对话客户端 | ✅ | 已完成 - ConversationClient |
| 任务客户端 | ✅ | 已完成 - TaskClient |
| 剧本客户端 | ✅ | 已完成 - ScreenplayClient |
| 媒体客户端 | ✅ | 已完成 - MediaClient |
| 数据模型 | ✅ | 已完成 - User, Conversation, Message, Task, Screenplay等 |

### 认证模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 登录页面 | ⏳ | 基础UI完成，待完善 |
| 注册页面 | ⏳ | 基础UI完成，待完善 |
| Token管理 | ✅ | 使用SharedPreferences存储 |
| 用户信息 | ⏳ | 待实现 |

### 对话模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 对话列表 | ❌ | 待实现 |
| 聊天界面 | ❌ | 待实现 |
| 消息发送 | ❌ | 待实现 |
| WebSocket连接 | ❌ | 待实现 |

### 剧本模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 剧本预览 | ❌ | 待实现 |
| 剧本详情 | ❌ | 待实现 |
| 场景展示 | ❌ | 待实现 |
| 角色设定 | ❌ | 待实现 |

### 任务模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 任务列表 | ❌ | 待实现 |
| 任务进度 | ❌ | 待实现 |
| 任务详情 | ❌ | 待实现 |

### Web适配层

| 功能 | 状态 | 说明 |
|------|------|------|
| 存储适配器 | ✅ | 已完成 - WebStorageAdapter |
| 视频适配器 | ✅ | 已完成 - WebVideoAdapter |
| 文件适配器 | ✅ | 已完成 - WebFileAdapter |
| 图片选择适配器 | ✅ | 已完成 - WebImagePickerAdapter |
| 响应式布局 | ✅ | 已完成 - ResponsiveLayout |
| PWA工具 | ✅ | 已完成 - PWAUtils |
| SEO工具 | ✅ | 已完成 - SEOUtils |

### 媒体模块

| 功能 | 状态 | 说明 |
|------|------|------|
| 图片预览 | ⏳ | 基础实现，待优化 |
| 视频播放 | ⏳ | 基础实现，待优化 |
| 图片缓存 | ✅ | 使用cached_network_image |
| 视频缓存 | ⏳ | 待实现 |

### Web适配

| 功能 | 状态 | 说明 |
|------|------|------|
| 存储适配器 | ✅ | 已实现 - WebStorageAdapter |
| Hive适配器 | ✅ | 已实现 - HiveWebAdapter |
| 视频适配器 | ✅ | 已实现 - WebVideoAdapter |
| 文件适配器 | ✅ | 已实现 - WebFileAdapter |
| 响应式布局 | ✅ | 已实现 - ResponsiveLayout |
| PWA工具 | ✅ | 已实现 - PwaUtils |
| SEO工具 | ✅ | 已实现 - SeoUtils |
| PWA配置 | ✅ | 已实现 - manifest.json |

---

## 🌐 Web适配

### 已实现的Web适配器

#### 1. WebStorageAdapter - 存储适配器

位置: `lib/web/adapters/storage_adapter.dart`

提供Web平台的本地存储功能，基于SharedPreferences实现。

**使用示例：**
```dart
import 'package:director_ai/web/adapters/storage_adapter.dart';

// 初始化（在应用启动时调用）
await WebStorageAdapter.initialize();

// 保存数据
await WebStorageAdapter.setString('key', 'value');
await WebStorageAdapter.setInt('count', 42);
await WebStorageAdapter.setBool('isLoggedIn', true);

// 读取数据
final value = await WebStorageAdapter.getString('key');
final count = await WebStorageAdapter.getInt('count');
final isLoggedIn = await WebStorageAdapter.getBool('isLoggedIn');

// 删除数据
await WebStorageAdapter.remove('key');

// 清空所有数据
await WebStorageAdapter.clear();
```

#### 2. HiveWebAdapter - Hive适配器

位置: `lib/web/adapters/hive_web_adapter.dart`

提供Web平台的Hive数据库初始化功能，使用IndexedDB作为底层存储。

**使用示例：**
```dart
import 'package:director_ai/web/adapters/hive_web_adapter.dart';

// 初始化（在应用启动时调用）
await HiveWebAdapter.initialize();

// 打开Box
final box = await HiveWebAdapter.openBox<String>('myBox');
await box.put('key', 'value');

// 打开懒加载Box
final lazyBox = await HiveWebAdapter.openLazyBox<String>('myLazyBox');
await lazyBox.put('key', 'value');

// 检查Box是否存在
final exists = await HiveWebAdapter.boxExists('myBox');

// 删除Box
await HiveWebAdapter.deleteBox('myBox');
```

#### 3. WebVideoAdapter - 视频适配器

位置: `lib/web/adapters/video_adapter.dart`

提供Web平台的视频播放功能，只支持网络URL视频源。

**使用示例：**
```dart
import 'package:director_ai/web/adapters/video_adapter.dart';

// 创建视频控制器
final controller = await WebVideoAdapter.createController(
  dataSource: 'https://example.com/video.mp4',
);

// 构建视频播放器Widget
final player = WebVideoAdapter.buildPlayer(
  controller,
  showControls: true,
);
```

#### 4. WebFileAdapter - 文件适配器

位置: `lib/web/adapters/file_adapter.dart`

提供Web平台的文件选择、上传、下载功能。

**使用示例：**
```dart
import 'package:director_ai/web/adapters/file_adapter.dart';
import 'package:image_picker/image_picker.dart';

// 选择单个图片
final image = await WebFileAdapter.pickImage(
  source: ImageSource.gallery,
);

// 选择多个图片
final images = await WebFileAdapter.pickMultipleImages();

// 下载文件
await WebFileAdapter.downloadFile(
  'https://example.com/file.pdf',
  'download.pdf',
);

// 下载Blob数据
await WebFileAdapter.downloadBlob(
  [1, 2, 3, 4, 5],
  'data.bin',
  mimeType: 'application/octet-stream',
);
```

#### 5. ResponsiveLayout - 响应式布局工具

位置: `lib/web/widgets/responsive_layout.dart`

提供响应式设计相关的工具方法和组件。

**使用示例：**
```dart
import 'package:director_ai/web/widgets/responsive_layout.dart';

// 检测屏幕类型
if (ResponsiveLayout.isMobile(context)) {
  // 移动端逻辑
} else if (ResponsiveLayout.isTablet(context)) {
  // 平板逻辑
} else if (ResponsiveLayout.isDesktop(context)) {
  // 桌面端逻辑
}

// 响应式值
final columns = ResponsiveLayout.responsiveValue(
  context,
  mobile: 1,
  tablet: 2,
  desktop: 3,
);

// 响应式容器
ResponsiveContainer(
  maxWidth: 1200,
  child: YourWidget(),
)

// 响应式网格
ResponsiveGridView(
  children: widgetList,
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 3,
)
```

#### 6. PwaUtils - PWA工具类

位置: `lib/web/utils/pwa_utils.dart`

提供Progressive Web App相关的工具方法。

**使用示例：**
```dart
import 'package:director_ai/web/utils/pwa_utils.dart';

// 检查是否已安装为PWA
final isInstalled = PwaUtils.isInstalled();

// 注册Service Worker
await PwaUtils.registerServiceWorker('/sw.js');

// 检查更新
await PwaUtils.checkForUpdate();

// 检查网络状态
final isOnline = PwaUtils.isOnline();
final networkStatus = PwaUtils.getNetworkStatus();
```

#### 7. SeoUtils - SEO工具类

位置: `lib/web/utils/seo_utils.dart`

提供搜索引擎优化相关的工具方法。

**使用示例：**
```dart
import 'package:director_ai/web/utils/seo_utils.dart';

// 设置页面标题
SeoUtils.setTitle('AI漫导 - 首页');

// 设置页面描述
SeoUtils.setDescription('AI智能体驱动的短剧制作平台');

// 设置Open Graph标签
SeoUtils.setOpenGraph('og:title', 'AI漫导');
SeoUtils.setOpenGraph('og:description', 'AI智能体驱动的短剧制作平台');

// 设置Twitter Card
SeoUtils.setTwitterCard('twitter:card', 'summary');
SeoUtils.setTwitterCard('twitter:title', 'AI漫导');
```

### 平台检测

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web平台代码
} else {
  // 移动端代码
}
```

### Web特定功能说明

- **文件上传**: 使用 `dart:html` 的 `FileUploadInputElement`
- **视频播放**: 使用 `video_player` 的 `VideoPlayerController.networkUrl`
- **存储**: 使用 `SharedPreferences` 或 `IndexedDB` (通过Hive)
- **下载**: 使用 `dart:html` 的 `AnchorElement`

---

## 🧪 测试指南

### 启动应用

```bash
# 移动端（Android）
flutter run -d android

# 移动端（iOS）
flutter run -d ios

# Web端
flutter run -d chrome

# 指定设备
flutter devices  # 查看可用设备
flutter run -d <device-id>
```

### 调试

```bash
# 热重载
r  # 在运行中按 r

# 热重启
R  # 在运行中按 R

# 打开DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### 代码分析

```bash
# 分析代码
flutter analyze

# 格式化代码
dart format lib/

# 检查依赖
flutter pub outdated
```

### 单元测试

```bash
# 运行测试
flutter test

# 运行特定测试文件
flutter test test/features/auth/auth_provider_test.dart

# 生成覆盖率报告
flutter test --coverage
```

---

## ❓ 常见问题

### 1. 依赖安装失败

**问题**: `flutter pub get` 失败

**解决**:
- 检查网络连接
- 清理缓存: `flutter pub cache clean`
- 更新Flutter: `flutter upgrade`
- 检查 `pubspec.yaml` 语法

### 2. 平台不支持

**问题**: `UnsupportedError: Platform not supported`

**解决**:
- 检查是否使用了条件导入
- 确认平台特定代码是否正确实现
- 检查 `pubspec.yaml` 中的平台配置

### 3. API请求失败

**问题**: `DioException` 或网络错误

**解决**:
- 检查API基础URL配置
- 确认后端服务运行
- 检查Token是否有效
- 查看网络请求日志

### 4. 视频无法播放

**问题**: 视频播放失败或黑屏

**解决**:
- 检查视频URL是否可访问
- 确认视频格式（Web端需要MP4 H.264）
- 检查CORS配置（Web端）
- 查看视频播放器日志

### 5. 存储失败

**问题**: `SharedPreferences` 或 `Hive` 初始化失败

**解决**:
- 检查存储权限（移动端）
- 确认存储路径可写
- 检查存储配额
- 查看错误日志

### 6. Web端构建失败

**问题**: `flutter build web` 失败

**解决**:
- 检查Flutter Web支持: `flutter config --enable-web`
- 清理构建缓存: `flutter clean`
- 检查依赖兼容性
- 查看构建日志

---

## 📚 参考文档

- [Web端工程实施方案](../docs/Web端工程实施方案.md)
- [API接口设计文档](../docs/API接口设计文档.md)
- [项目结构规划](../docs/项目结构规划.md)
- [Flutter官方文档](https://docs.flutter.dev/)
- [Dart官方文档](https://dart.dev/)
- [Provider文档](https://pub.dev/packages/provider)
- [Dio文档](https://pub.dev/packages/dio)

---

## 🚀 下一步工作

### 优先级高

1. ❌ 实现认证功能（登录、注册）
2. ❌ 实现对话功能（聊天界面、消息列表）
3. ❌ 实现剧本功能（预览、详情）
4. ❌ 实现任务功能（列表、进度）
5. ❌ 实现WebSocket实时通信
6. ❌ 实现Web适配层

### 优先级中

1. ❌ 完善UI/UX设计
2. ❌ 添加错误处理和重试机制
3. ❌ 实现离线缓存
4. ❌ 添加单元测试
5. ❌ 性能优化

### 优先级低

1. ❌ 添加国际化支持
2. ❌ 实现深色模式
3. ❌ 添加动画效果
4. ❌ 完善文档

---

## 📝 更新日志

### 2026-01-12

- ✅ 实现Web适配层完整功能
  - ✅ WebStorageAdapter - Web存储适配器（支持SharedPreferences）
  - ✅ WebVideoAdapter - Web视频播放适配器（支持网络URL视频播放）
  - ✅ WebFileAdapter - Web文件操作适配器（文件选择、下载等）
  - ✅ WebImagePickerAdapter - Web图片选择适配器
  - ✅ ResponsiveLayout - 响应式布局工具（移动端/平板/桌面端适配）
  - ✅ PWAUtils - PWA工具类（Service Worker、安装检测等）
  - ✅ SEOUtils - SEO工具类（Meta标签、Open Graph、Twitter Card等）
  - ✅ 创建Web适配层文档（lib/web/README.md）

- ✅ 实现API客户端模块完整功能
  - ✅ ApiClient - API客户端基类（包含错误处理、Token管理、日志拦截器）
  - ✅ AuthClient - 认证客户端（登录、注册、Token刷新、用户信息）
  - ✅ ConversationClient - 对话客户端（创建、列表、详情、更新、删除、消息列表）
  - ✅ TaskClient - 任务客户端（创建、列表、详情、进度、取消、删除）
  - ✅ ScreenplayClient - 剧本客户端（生成草稿、确认、详情、更新）
  - ✅ MediaClient - 媒体客户端（上传图片、生成图片/视频）
  - ✅ 数据模型 - User, Conversation, Message, Task, Screenplay, Scene, CharacterSheet等
  - ✅ 配置文件 - ApiConfig
  - ✅ 导出文件和文档

- ✅ 实现Web适配层完整功能
  - ✅ WebStorageAdapter - Web存储适配器
  - ✅ HiveWebAdapter - Hive Web适配器
  - ✅ WebVideoAdapter - Web视频播放器适配器
  - ✅ WebFileAdapter - Web文件选择/下载适配器
  - ✅ ResponsiveLayout - 响应式布局工具
  - ✅ PwaUtils - PWA工具类
  - ✅ SeoUtils - SEO工具类
  - ✅ manifest.json - PWA配置文件

### 2025-01-12

- ✅ 创建项目基础结构
- ✅ 配置开发环境
- ✅ 实现基础依赖配置
- ✅ 创建开发施工文档

---

**文档版本**: v1.1  
**最后更新**: 2026-01-12  
**维护者**: 开发团队
