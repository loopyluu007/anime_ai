class FileAdapter {
  static void downloadFile(String url, String filename) {
    throw UnsupportedError('需要平台特定实现');
  }
  
  static Future<dynamic> selectFile({String? accept}) async {
    throw UnsupportedError('需要平台特定实现');
  }
}
