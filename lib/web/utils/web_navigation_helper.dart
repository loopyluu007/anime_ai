import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web端导航辅助工具
/// 提供Web端特定的导航功能
class WebNavigationHelper {
  /// 检查是否为Web平台
  static bool get isWeb => kIsWeb;

  /// 导航到指定路由（Web端支持浏览器历史）
  static Future<T?>? navigateTo<T>(
    BuildContext context,
    String route, {
    Object? arguments,
    bool replace = false,
  }) {
    if (!kIsWeb) {
      // 移动端使用标准导航
      if (replace) {
        return Navigator.of(context).pushReplacementNamed(
          route,
          arguments: arguments,
        );
      } else {
        return Navigator.of(context).pushNamed(
          route,
          arguments: arguments,
        );
      }
    }

    // Web端：更新URL并导航
    // 注意：这需要配合dart:html实现URL更新
    // 这里提供基础实现
    if (replace) {
      return Navigator.of(context).pushReplacementNamed(
        route,
        arguments: arguments,
      );
    } else {
      return Navigator.of(context).pushNamed(
        route,
        arguments: arguments,
      );
    }
  }

  /// 返回上一页（Web端支持浏览器后退）
  static void goBack<T>(BuildContext context, [T? result]) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    } else if (kIsWeb) {
      // Web端：如果没有页面可返回，可以关闭窗口或返回首页
      // 这里暂时不做处理，让浏览器处理
    }
  }

  /// 获取当前路由
  static String? getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name;
  }

  /// 检查是否可以返回
  static bool canGoBack(BuildContext context) {
    return Navigator.of(context).canPop();
  }
}
