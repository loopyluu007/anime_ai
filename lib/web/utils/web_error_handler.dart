import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Web端错误处理工具
/// 提供Web端特定的错误处理和用户提示
class WebErrorHandler {
  /// 显示错误提示
  /// 
  /// Web端使用SnackBar，移动端可以使用其他方式
  static void showError(BuildContext context, String message, {Duration? duration}) {
    if (!kIsWeb) {
      // 移动端可以使用其他提示方式
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: duration ?? const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Web端：使用SnackBar，但可以添加更多样式
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: '关闭',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// 显示成功提示
  static void showSuccess(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: duration ?? const Duration(seconds: 2),
        behavior: kIsWeb ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        margin: kIsWeb ? const EdgeInsets.all(16) : null,
      ),
    );
  }

  /// 显示信息提示
  static void showInfo(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: duration ?? const Duration(seconds: 3),
        behavior: kIsWeb ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
        margin: kIsWeb ? const EdgeInsets.all(16) : null,
      ),
    );
  }

  /// 显示确认对话框（Web端优化）
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确定',
    String cancelText = '取消',
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: confirmColor ?? Theme.of(context).primaryColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 处理网络错误
  static void handleNetworkError(BuildContext context, dynamic error) {
    String message = '网络错误，请检查网络连接';
    
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = '连接超时，请稍后重试';
          break;
        case DioExceptionType.badResponse:
          message = '服务器错误：${error.response?.statusCode}';
          break;
        case DioExceptionType.cancel:
          message = '请求已取消';
          break;
        default:
          message = '网络错误：${error.message}';
      }
    }
    
    showError(context, message);
  }

  /// 处理API错误
  static void handleApiError(BuildContext context, dynamic error) {
    String message = '操作失败，请稍后重试';
    
    if (error is DioException && error.response != null) {
      final statusCode = error.response!.statusCode;
      switch (statusCode) {
        case 401:
          message = '未授权，请重新登录';
          break;
        case 403:
          message = '没有权限执行此操作';
          break;
        case 404:
          message = '资源不存在';
          break;
        case 500:
          message = '服务器内部错误';
          break;
        default:
          message = '请求失败：$statusCode';
      }
    }
    
    showError(context, message);
  }
}
