import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'core/api/api_client.dart';
import 'core/api/auth_client.dart';
import 'core/api/conversation_client.dart';
import 'core/api/task_client.dart';
import 'core/storage/local_storage.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/chat/providers/conversation_provider.dart';
import 'features/chat/providers/websocket_provider.dart';
import 'features/gallery/providers/gallery_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/task/providers/task_provider.dart';
import 'features/task/screens/task_list_screen.dart';
import 'shared/themes/app_theme.dart';
import 'web/screens/web_home_screen.dart';
import 'core/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化本地存储
  await LocalStorage.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 初始化认证客户端（内部会创建 ApiClient）
    final apiClient = ApiClient(
      getToken: () async {
        // 从 SharedPreferences 获取 token
        return await LocalStorage.getString('auth_token');
      },
    );
    final authClient = AuthClient(apiClient);

    // 创建 API 客户端和对话客户端
    final conversationClient = ConversationClient(apiClient);
    final taskClient = TaskClient(apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authClient),
        ),
        ChangeNotifierProvider(
          create: (_) => GalleryProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = SettingsProvider();
            provider.initialize();
            return provider;
          },
        ),
        // WebSocket Provider
        ChangeNotifierProvider(
          create: (_) {
            final provider = WebSocketProvider(
              getToken: () async => await LocalStorage.getString('auth_token'),
            );
            // 在用户登录后自动连接
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeWebSocket(provider);
            });
            return provider;
          },
        ),
        // Conversation Provider
        ChangeNotifierProvider(
          create: (_) {
            final provider = ConversationProvider(conversationClient);
            // 延迟设置 WebSocket Provider（确保 WebSocket Provider 已创建）
            WidgetsBinding.instance.addPostFrameCallback((__) {
              try {
                final wsProvider = Provider.of<WebSocketProvider>(_, listen: false);
                provider.setWebSocketProvider(wsProvider);
                wsProvider.setConversationProvider(provider);
              } catch (e) {
                debugPrint('设置 WebSocket Provider 失败: $e');
              }
            });
            return provider;
          },
        ),
        // Task Provider
        ChangeNotifierProvider(
          create: (_) {
            final provider = TaskProvider(taskClient);
            // 延迟设置 WebSocket Provider（确保 WebSocket Provider 已创建）
            WidgetsBinding.instance.addPostFrameCallback((__) {
              try {
                final wsProvider = Provider.of<WebSocketProvider>(_, listen: false);
                provider.setWebSocketProvider(wsProvider);
              } catch (e) {
                debugPrint('设置 Task WebSocket Provider 失败: $e');
              }
            });
            return provider;
          },
        ),
        // Chat Provider (在需要时创建)
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return MaterialApp(
            title: 'AI漫导',
            debugShowCheckedModeBanner: false,
            theme: settingsProvider.getCurrentTheme(),
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsProvider.getMaterialThemeMode(),
            home: const AuthWrapper(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => kIsWeb ? const WebHomeScreen() : const HomeScreen(),
            },
            onGenerateRoute: (settings) {
              // 使用AppRouter处理动态路由
              return AppRouter.onGenerateRoute(settings) ?? 
                MaterialPageRoute(
                  builder: (context) => const Scaffold(
                    body: Center(child: Text('页面未找到')),
                  ),
                );
            },
          );
        },
      ),
    );
  }

  /// 初始化 WebSocket 连接
  void _initializeWebSocket(WebSocketProvider provider) {
    // 延迟初始化，确保 Token 已设置
    Future.delayed(const Duration(seconds: 1), () async {
      final token = await LocalStorage.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        try {
          await provider.initialize();
        } catch (e) {
          debugPrint('WebSocket 初始化失败: $e');
        }
      }
    });
  }
}

/// 认证包装器 - 根据认证状态显示不同页面
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // 检查认证状态
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.loading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.isAuthenticated) {
          // 用户已登录，初始化 WebSocket
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
            wsProvider.initialize();
          });
          // Web端使用WebHomeScreen，移动端使用HomeScreen
          return kIsWeb ? const WebHomeScreen() : const HomeScreen();
        } else {
          // 用户未登录，断开 WebSocket
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
            wsProvider.disconnect();
          });
          return const LoginScreen();
        }
      },
    );
  }
}

/// 主页（临时）
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI漫导'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
            tooltip: '登出',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (authProvider.user != null) ...[
              Text(
                '欢迎, ${authProvider.user!.username}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.user!.email,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.task_alt),
              label: const Text('查看任务列表'),
            ),
          ],
        ),
      ),
    );
  }
}
