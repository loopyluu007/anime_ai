import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web端剪贴板适配器
class ClipboardAdapter {
  /// 复制文本到剪贴板（Web端）
  /// 
  /// [text] 要复制的文本
  /// 
  /// 返回是否成功
  static Future<bool> copyText(String text) async {
    if (!kIsWeb) {
      throw UnsupportedError('ClipboardAdapter 仅支持 Web 平台');
    }

    try {
      // 方法1：使用Clipboard API（需要HTTPS或localhost）
      if (html.window.navigator.clipboard != null) {
        await html.window.navigator.clipboard!.writeText(text);
        return true;
      }
    } catch (e) {
      // 如果Clipboard API失败，使用fallback方法
    }

    try {
      // 方法2：使用textarea元素（兼容性更好）
      final textarea = html.TextAreaElement()
        ..value = text
        ..style.position = 'absolute'
        ..style.left = '-9999px';
      
      html.document.body?.append(textarea);
      textarea.select();
      
      final success = html.document.execCommand('copy');
      textarea.remove();
      
      return success;
    } catch (e) {
      return false;
    }
  }
}
