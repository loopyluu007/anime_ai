import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../web/adapters/clipboard_adapter.dart';
// 条件导入：Web端使用dart:html，非Web端使用stub
import 'package:director_ai/web/stubs/html_stub.dart' as html if (dart.library.html) 'dart:html' as html;

/// 分享服务
/// 
/// 提供跨平台的分享功能（移动端和Web端）
class ShareService {
  /// 分享URL
  /// 
  /// [url] 要分享的URL
  /// [title] 分享标题（可选）
  /// 
  /// Web端：优先使用Web Share API，否则复制URL到剪贴板
  /// 移动端：使用url_launcher打开URL（实际项目中应使用share_plus包）
  Future<void> shareUrl(String url, {String? title}) async {
    if (kIsWeb) {
      // Web端：优先使用Web Share API
      try {
        if (html.window.navigator.share != null) {
          await html.window.navigator.share!({
            'title': title ?? '分享链接',
            'url': url,
          });
          return;
        }
      } catch (e) {
        // Web Share API不可用或用户取消，降级到剪贴板
      }
      
      // 降级方案：复制URL到剪贴板
      final success = await ClipboardAdapter.copyText(url);
      if (!success) {
        throw Exception('复制到剪贴板失败');
      }
    } else {
      // 移动端：打开URL（实际应该使用share_plus包进行系统分享）
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 如果无法打开，尝试复制到剪贴板
        await Clipboard.setData(ClipboardData(text: url));
      }
    }
  }

  /// 分享文本
  /// 
  /// [text] 要分享的文本
  Future<void> shareText(String text) async {
    if (kIsWeb) {
      final success = await ClipboardAdapter.copyText(text);
      if (!success) {
        throw Exception('复制到剪贴板失败');
      }
    } else {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }
}
