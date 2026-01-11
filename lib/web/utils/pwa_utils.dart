import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

/// PWA工具类
/// 提供Progressive Web App相关功能
class PWAUtils {
  /// 检查是否已安装为PWA
  static bool get isInstalled {
    if (!kIsWeb) return false;
    
    // 检查是否在standalone模式下运行（PWA安装后）
    return html.window.matchMedia('(display-mode: standalone)').matches ||
           html.window.matchMedia('(display-mode: fullscreen)').matches ||
           html.window.matchMedia('(display-mode: minimal-ui)').matches;
  }

  /// 检查是否支持PWA安装
  static bool get canInstall {
    if (!kIsWeb) return false;
    
    // 检查是否已经有beforeinstallprompt事件监听器
    // 这需要在HTML中设置
    return true; // 简化实现，实际应该检查事件支持
  }

  /// 显示安装提示
  /// 
  /// 注意：这需要在HTML中监听beforeinstallprompt事件
  static Future<bool> promptInstall() async {
    if (!kIsWeb) {
      throw UnsupportedError('PWAUtils 仅支持 Web 平台');
    }

    // 实际实现需要在HTML中处理beforeinstallprompt事件
    // 这里提供一个占位实现
    return false;
  }

  /// 检查Service Worker是否已注册
  static Future<bool> isServiceWorkerRegistered() async {
    if (!kIsWeb) return false;

    try {
      final registration = await html.window.navigator.serviceWorker?.ready;
      return registration != null;
    } catch (e) {
      return false;
    }
  }

  /// 注册Service Worker
  /// 
  /// [scriptUrl] Service Worker脚本的URL
  static Future<bool> registerServiceWorker(String scriptUrl) async {
    if (!kIsWeb) {
      throw UnsupportedError('PWAUtils 仅支持 Web 平台');
    }

    try {
      final registration = await html.window.navigator.serviceWorker?.register(
        scriptUrl,
      );
      return registration != null;
    } catch (e) {
      debugPrint('Service Worker注册失败: $e');
      return false;
    }
  }

  /// 取消注册Service Worker
  static Future<bool> unregisterServiceWorker() async {
    if (!kIsWeb) {
      throw UnsupportedError('PWAUtils 仅支持 Web 平台');
    }

    try {
      final registration = await html.window.navigator.serviceWorker?.ready;
      if (registration != null) {
        final success = await registration.unregister();
        return success;
      }
      return false;
    } catch (e) {
      debugPrint('Service Worker取消注册失败: $e');
      return false;
    }
  }

  /// 检查是否在线
  static bool get isOnline {
    if (!kIsWeb) return true;
    return html.window.navigator.onLine;
  }

  /// 监听在线状态变化
  static void listenOnlineStatus(Function(bool isOnline) callback) {
    if (!kIsWeb) return;

    html.window.addEventListener('online', (event) {
      callback(true);
    });

    html.window.addEventListener('offline', (event) {
      callback(false);
    });
  }

  /// 获取应用版本（从manifest）
  static String? getAppVersion() {
    if (!kIsWeb) return null;

    // 实际实现需要从manifest.json读取
    // 这里提供一个占位实现
    return null;
  }

  /// 检查更新
  /// 
  /// 检查Service Worker是否有更新
  static Future<bool> checkForUpdate() async {
    if (!kIsWeb) return false;

    try {
      final registration = await html.window.navigator.serviceWorker?.ready;
      if (registration != null) {
        await registration.update();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return false;
    }
  }

  /// 清除缓存
  static Future<void> clearCache() async {
    if (!kIsWeb) {
      throw UnsupportedError('PWAUtils 仅支持 Web 平台');
    }

    try {
      final cacheNames = await html.window.caches?.keys();
      if (cacheNames != null) {
        for (final cacheName in cacheNames) {
          await html.window.caches?.delete(cacheName);
        }
      }
    } catch (e) {
      debugPrint('清除缓存失败: $e');
    }
  }
}
