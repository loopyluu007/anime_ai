import '../../core/utils/formatters.dart';

class FileUtils {
  // 格式化文件大小
  static String formatFileSize(int bytes) {
    return Formatters.formatFileSize(bytes);
  }
  
  // 获取文件扩展名
  static String getExtension(String filename) {
    final parts = filename.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }
  
  // 检查是否为图片
  static bool isImage(String filename) {
    final ext = getExtension(filename);
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
  }
  
  // 检查是否为视频
  static bool isVideo(String filename) {
    final ext = getExtension(filename);
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }
}
