import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/chat/screens/conversation_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/models/conversation.dart';
import '../../features/screenplay/screens/screenplay_detail_screen.dart';
import '../../features/screenplay/screens/screenplay_review_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/gallery/screens/gallery_screen.dart';
import '../../features/task/screens/task_list_screen.dart';
import '../../web/screens/web_home_screen.dart';

class AppRouter {
  static const String initialRoute = '/login';
  
  static final Map<String, WidgetBuilder> routes = {
    '/login': (context) => const LoginScreen(),
    '/register': (context) => const RegisterScreen(),
    '/home': (context) => kIsWeb 
        ? const WebHomeScreen() 
        : const WebHomeScreen(), // 移动端使用HomeScreen，这里暂时都用WebHomeScreen
    '/conversations': (context) => const ConversationListScreen(),
    '/tasks': (context) => const TaskListScreen(),
    '/settings': (context) => const SettingsScreen(),
    '/gallery': (context) => const GalleryScreen(),
  };
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // 处理动态路由
    switch (settings.name) {
      case '/chat':
        final args = settings.arguments as Map<String, dynamic>?;
        final conversation = args?['conversation'] as Conversation?;
        if (conversation == null) {
          // 如果没有传递 conversation，返回错误页面或首页
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text('对话不存在')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversation: conversation,
          ),
        );
      case '/screenplay/review':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ScreenplayReviewScreen(
            screenplayId: args?['screenplayId'] ?? '',
          ),
        );
      case '/screenplay/detail':
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ScreenplayDetailScreen(
            screenplayId: args?['screenplayId'] ?? '',
          ),
        );
      default:
        return null;
    }
  }
  
  /// Web端路由转换
  /// 将URL路径转换为路由名称
  static String? urlToRoute(String? url) {
    if (url == null || url.isEmpty) return null;
    
    // 移除查询参数和锚点
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    
    final path = uri.path;
    if (path.isEmpty || path == '/') return '/home';
    
    // 检查是否在路由表中
    if (routes.containsKey(path)) {
      return path;
    }
    
    return null;
  }
  
  /// 路由转URL
  /// 将路由名称转换为URL路径
  static String routeToUrl(String route) {
    if (route.startsWith('/')) {
      return route;
    }
    return '/$route';
  }
}
