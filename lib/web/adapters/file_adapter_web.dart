import 'dart:html' as html;

class FileAdapter {
  static void downloadFile(String url, String filename) {
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
  }
  
  static Future<html.FileUploadInputElement?> selectFile({
    String? accept,
  }) async {
    final input = html.FileUploadInputElement();
    if (accept != null) {
      input.accept = accept;
    }
    input.click();
    return input;
  }
}
