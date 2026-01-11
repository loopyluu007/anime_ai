import 'package:flutter/foundation.dart' show kIsWeb;

/// Web平台工具类
/// 提供Web平台特定的工具函数
class WebPlatformUtils {
  /// 检查是否为Web平台
  static bool get isWeb => kIsWeb;

  /// 检查是否为移动端Web
  static bool isMobileWeb() {
    if (!kIsWeb) return false;
    // 可以通过检查User-Agent或屏幕尺寸来判断
    // 这里简化处理，实际应该使用更精确的方法
    return false; // 需要根据实际情况实现
  }

  /// 获取浏览器信息
  static String? getBrowserInfo() {
    if (!kIsWeb) return null;
    // Web端可以通过JavaScript获取浏览器信息
    // 这里需要配合dart:html实现
    return null;
  }

  /// 检查PWA安装状态
  static bool isPWAInstalled() {
    if (!kIsWeb) return false;
    // 检查是否在standalone模式下运行
    // 需要配合dart:html实现
    return false;
  }

  /// 提示安装PWA
  static Future<void> promptInstallPWA() async {
    if (!kIsWeb) return;
    // 触发PWA安装提示
    // 需要配合dart:html实现
  }
}
