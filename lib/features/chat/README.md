# Chat 模块

聊天功能模块，包含对话管理和消息发送功能。

## 📁 目录结构

```
lib/features/chat/
├── models/                    # 数据模型
│   ├── message.dart          # 消息模型
│   └── conversation.dart     # 对话模型
├── providers/                 # 状态管理
│   ├── chat_provider.dart    # 聊天状态管理
│   └── conversation_provider.dart  # 对话列表状态管理
├── widgets/                   # UI组件
│   ├── message_bubble.dart   # 消息气泡
│   ├── message_input.dart    # 消息输入框
│   └── screenplay_card.dart # 剧本卡片
├── screens/                  # 界面
│   ├── chat_screen.dart      # 聊天界面
│   └── conversation_list_screen.dart  # 对话列表界面
└── README.md                 # 本文档
```

## 🚀 使用方法

### 1. 配置 Provider

在应用入口处配置 Provider：

```dart
import 'package:provider/provider.dart';
import 'package:director_ai/core/api/api_client.dart';
import 'package:director_ai/core/api/conversation_client.dart';
import 'package:director_ai/features/chat/providers/chat_provider.dart';
import 'package:director_ai/features/chat/providers/conversation_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 创建API客户端（需要提供Token获取函数）
    final apiClient = ApiClient(
      getToken: () => 'your_token_here', // 从SharedPreferences获取
    );
    final conversationClient = ConversationClient(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConversationProvider(conversationClient),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(conversationClient),
        ),
      ],
      child: MaterialApp(
        // ...
      ),
    );
  }
}
```

### 2. 使用对话列表界面

```dart
import 'package:director_ai/features/chat/screens/conversation_list_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ConversationListScreen(),
  ),
);
```

### 3. 使用聊天界面

```dart
import 'package:director_ai/features/chat/screens/chat_screen.dart';
import 'package:director_ai/features/chat/models/conversation.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatScreen(conversation: conversation),
  ),
);
```

### 4. 在代码中使用 Provider

```dart
import 'package:provider/provider.dart';
import 'package:director_ai/features/chat/providers/conversation_provider.dart';

// 获取对话列表
final provider = context.read<ConversationProvider>();
await provider.loadConversations(refresh: true);

// 创建新对话
final conversation = await provider.createConversation('新对话');

// 监听对话列表变化
Consumer<ConversationProvider>(
  builder: (context, provider, child) {
    return ListView.builder(
      itemCount: provider.conversations.length,
      itemBuilder: (context, index) {
        final conversation = provider.conversations[index];
        return ListTile(title: Text(conversation.title));
      },
    );
  },
)
```

## 📝 API 接口

### 对话管理

- `POST /conversations` - 创建对话
- `GET /conversations` - 获取对话列表
- `GET /conversations/{id}` - 获取对话详情
- `PUT /conversations/{id}` - 更新对话
- `DELETE /conversations/{id}` - 删除对话

### 消息管理

- `GET /conversations/{id}/messages` - 获取消息列表
- `POST /conversations/{id}/messages` - 发送消息

详细API文档请参考：`docs/03-api-database/API接口设计文档.md`

## 🎨 功能特性

### 已实现功能

- ✅ 对话列表展示
- ✅ 创建/删除对话
- ✅ 对话置顶/取消置顶
- ✅ 消息发送
- ✅ 消息列表展示
- ✅ Markdown 消息渲染
- ✅ 剧本消息卡片
- ✅ 下拉刷新
- ✅ 分页加载
- ✅ 错误处理

### 待实现功能

- ⏳ WebSocket 实时消息推送
- ⏳ 消息状态（发送中/已发送/已读）
- ⏳ 图片/视频消息
- ⏳ 消息搜索
- ⏳ 消息复制/转发
- ⏳ 语音消息

## 🔧 自定义配置

### 修改 API 基础 URL

编辑 `lib/core/config/api_config.dart`：

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.example.com/api/v1';
  static const String wsUrl = 'wss://api.example.com/ws';
}
```

### 自定义消息气泡样式

编辑 `lib/features/chat/widgets/message_bubble.dart`，修改样式和布局。

### 自定义输入框样式

编辑 `lib/features/chat/widgets/message_input.dart`，修改输入框外观和行为。

## 🐛 常见问题

### 1. Token 未设置

确保在创建 `ApiClient` 时提供正确的 Token 获取函数：

```dart
final apiClient = ApiClient(
  getToken: () async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  },
);
```

### 2. 网络请求失败

检查：
- API 基础 URL 是否正确
- 后端服务是否运行
- Token 是否有效
- 网络连接是否正常

### 3. 消息不显示

检查：
- 消息列表是否正确加载
- Provider 是否正确配置
- 消息数据格式是否正确

## 📚 相关文档

- [API接口设计文档](../../../docs/03-api-database/API接口设计文档.md)
- [数据库设计文档](../../../docs/03-api-database/数据库设计文档.md)
- [前端开发文档](../../../frontend/DEVELOPMENT.md)
