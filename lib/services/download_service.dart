import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../web/adapters/file_adapter.dart';

// 条件导入：移动端使用 dart:io
import 'dart:io' if (dart.library.html) 'dart:html' as io;

/// 下载服务
/// 
/// 提供跨平台的下载功能（移动端和Web端）
class DownloadService {
  final Dio _dio = Dio();

  /// 下载文件
  /// 
  /// [url] 文件URL
  /// [filename] 保存的文件名（可选，如果不提供则从URL提取）
  /// [onProgress] 下载进度回调
  /// 
  /// 返回下载文件的路径（移动端）或null（Web端直接下载）
  Future<String?> downloadFile(
    String url, {
    String? filename,
    void Function(int received, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      // Web端：直接触发浏览器下载
      final name = filename ?? _extractFilenameFromUrl(url);
      await WebFileAdapter.downloadFile(url, name);
      return null;
    } else {
      // 移动端：下载到本地存储
      return await _downloadToLocal(url, filename: filename, onProgress: onProgress);
    }
  }

  /// 下载到本地（移动端）
  Future<String> _downloadToLocal(
    String url, {
    String? filename,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      // 获取下载目录
      final directory = await _getDownloadDirectory();
      final name = filename ?? _extractFilenameFromUrl(url);
      final filePath = path.join(directory.path, name);

      // 下载文件
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: onProgress,
      );

      return filePath;
    } catch (e) {
      throw Exception('下载失败: $e');
    }
  }

  /// 获取下载目录
  Future<io.Directory> _getDownloadDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web端不支持本地文件系统');
    }
    
    // 在非Web平台，根据平台类型选择下载目录
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android: 尝试使用外部存储的Download目录
      try {
        // 使用 path_provider 的 getApplicationDocumentsDirectory 返回的 Directory
        final appDir = await getApplicationDocumentsDirectory();
        // 创建下载子目录
        final downloadDir = io.Directory('${appDir.path}/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        return downloadDir;
      } catch (_) {
        // 如果无法访问，使用应用文档目录
        return await getApplicationDocumentsDirectory();
      }
    }
    // iOS 和其他平台使用应用文档目录
    return await getApplicationDocumentsDirectory();
  }

  /// 从URL提取文件名
  String _extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
          return lastSegment;
        }
      }
      // 如果无法从URL提取，使用默认名称
      final extension = _getExtensionFromUrl(url);
      return 'download_${DateTime.now().millisecondsSinceEpoch}$extension';
    } catch (e) {
      final extension = _getExtensionFromUrl(url);
      return 'download_${DateTime.now().millisecondsSinceEpoch}$extension';
    }
  }

  /// 从URL获取文件扩展名
  String _getExtensionFromUrl(String url) {
    if (url.contains('?')) {
      url = url.split('?').first;
    }
    if (url.contains('#')) {
      url = url.split('#').first;
    }
    final dotIndex = url.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < url.length - 1) {
      final ext = url.substring(dotIndex);
      // 限制扩展名长度
      if (ext.length <= 10) {
        return ext;
      }
    }
    // 根据URL判断可能的类型
    if (url.contains('image') || url.contains('jpg') || url.contains('jpeg') || url.contains('png')) {
      return '.jpg';
    } else if (url.contains('video') || url.contains('mp4') || url.contains('mov')) {
      return '.mp4';
    }
    return '';
  }
}
