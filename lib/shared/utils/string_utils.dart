class StringUtils {
  // 截断字符串
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}$suffix';
  }
  
  // 检查是否为空
  static bool isEmpty(String? text) {
    return text == null || text.trim().isEmpty;
  }
  
  // 检查是否不为空
  static bool isNotEmpty(String? text) {
    return !isEmpty(text);
  }
  
  // 首字母大写
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}
