import 'package:intl/intl.dart';
import '../../core/utils/formatters.dart';

class AppDateUtils {
  // 格式化日期时间
  static String formatDateTime(DateTime dateTime, {String pattern = 'yyyy-MM-dd HH:mm:ss'}) {
    return Formatters.formatDateTime(dateTime, pattern: pattern);
  }
  
  // 格式化日期
  static String formatDate(DateTime dateTime, {String pattern = 'yyyy-MM-dd'}) {
    return Formatters.formatDate(dateTime, pattern: pattern);
  }
  
  // 格式化时间
  static String formatTime(DateTime dateTime, {String pattern = 'HH:mm:ss'}) {
    return Formatters.formatTime(dateTime, pattern: pattern);
  }
  
  // 相对时间
  static String formatRelativeTime(DateTime dateTime) {
    return Formatters.formatRelativeTime(dateTime);
  }
}
