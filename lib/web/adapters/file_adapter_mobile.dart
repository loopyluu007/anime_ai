import 'package:image_picker/image_picker.dart';

class FileAdapter {
  static void downloadFile(String url, String filename) {
    throw UnsupportedError('移动端需要使用平台通道');
  }
  
  static Future<XFile?> selectFile({String? accept}) async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery);
  }
}
