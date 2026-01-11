import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

/// Web 文件适配器
/// 提供Web平台特定的文件操作实现
class WebFileAdapter {
  /// 选择图片（Web 端）
  /// 
  /// 返回选择的图片文件，如果用户取消选择则返回null
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebFileAdapter 仅支持 Web 平台');
    }

    if (source == ImageSource.camera) {
      // Web端不支持相机，使用图库代替
      return pickImage(source: ImageSource.gallery);
    }

    final completer = Completer<XFile?>();
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is String) {
          // 提取 base64 数据
          final base64 = result.split(',')[1];
          final bytes = base64Decode(base64);

          completer.complete(XFile.fromData(
            bytes,
            mimeType: file.type,
            name: file.name,
            length: bytes.length,
          ));
        } else {
          completer.complete(null);
        }
      });

      reader.readAsDataUrl(file);
    });

    return completer.future;
  }

  /// 选择多个图片（Web 端）
  static Future<List<XFile>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebFileAdapter 仅支持 Web 平台');
    }

    final completer = Completer<List<XFile>>();
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.multiple = true;
    uploadInput.click();

    final List<XFile> files = [];

    uploadInput.onChange.listen((e) {
      final selectedFiles = uploadInput.files;
      if (selectedFiles == null || selectedFiles.isEmpty) {
        completer.complete([]);
        return;
      }

      int loadedCount = 0;
      final totalCount = selectedFiles.length;

      for (final file in selectedFiles) {
        final reader = html.FileReader();
        reader.onLoadEnd.listen((e) {
          final result = reader.result;
          if (result is String) {
            final base64 = result.split(',')[1];
            final bytes = base64Decode(base64);

            files.add(XFile.fromData(
              bytes,
              mimeType: file.type,
              name: file.name,
              length: bytes.length,
            ));

            loadedCount++;
            if (loadedCount == totalCount) {
              completer.complete(files);
            }
          } else {
            loadedCount++;
            if (loadedCount == totalCount) {
              completer.complete(files);
            }
          }
        });

        reader.readAsDataUrl(file);
      }
    });

    return completer.future;
  }

  /// 选择文件（Web 端）
  /// 
  /// [accept] 接受的文件类型，例如 'image/*', 'video/*', '.pdf' 等
  static Future<XFile?> pickFile({
    String? accept,
    bool multiple = false,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebFileAdapter 仅支持 Web 平台');
    }

    final completer = Completer<XFile?>();
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    if (accept != null) {
      uploadInput.accept = accept;
    }
    uploadInput.multiple = multiple;
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final file = uploadInput.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }

      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final result = reader.result;
        if (result is String) {
          final base64 = result.split(',')[1];
          final bytes = base64Decode(base64);

          completer.complete(XFile.fromData(
            bytes,
            mimeType: file.type,
            name: file.name,
            length: bytes.length,
          ));
        } else {
          completer.complete(null);
        }
      });

      reader.readAsDataUrl(file);
    });

    return completer.future;
  }

  /// 下载文件（Web 端）
  /// 
  /// [url] 文件的URL
  /// [filename] 下载后的文件名
  static Future<void> downloadFile(String url, String filename) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebFileAdapter 仅支持 Web 平台');
    }

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
  }

  /// 下载字节数据为文件（Web 端）
  /// 
  /// [bytes] 文件的字节数据
  /// [filename] 下载后的文件名
  /// [mimeType] 文件的MIME类型
  static Future<void> downloadBytes(
    Uint8List bytes,
    String filename, {
    String? mimeType,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebFileAdapter 仅支持 Web 平台');
    }

    final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
    final url = html.Url.createObjectUrlFromBlob(blob);

    try {
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      
      // 清理URL对象
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      html.Url.revokeObjectUrl(url);
      rethrow;
    }
  }

  /// 打开文件选择对话框并读取为字节
  /// 
  /// [accept] 接受的文件类型
  static Future<Uint8List?> pickFileAsBytes({String? accept}) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebFileAdapter 仅支持 Web 平台');
    }

    final file = await pickFile(accept: accept);
    if (file == null) {
      return null;
    }

    return await file.readAsBytes();
  }

  /// 将文件转换为Base64字符串
  static Future<String?> fileToBase64(XFile file) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebFileAdapter 仅支持 Web 平台');
    }

    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      return null;
    }
  }
}
