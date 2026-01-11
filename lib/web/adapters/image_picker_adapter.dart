import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'file_adapter.dart';

/// Web 图片选择适配器
/// 提供Web平台特定的图片选择功能
class WebImagePickerAdapter {
  /// 图片选择器实例
  static final ImagePicker _picker = ImagePicker();

  /// 从图库选择图片（Web端）
  /// 
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// [imageQuality] 图片质量（0-100）
  static Future<XFile?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebImagePickerAdapter 仅支持 Web 平台');
    }

    // Web端使用文件适配器
    return await WebFileAdapter.pickImage(
      source: ImageSource.gallery,
      maxWidth: maxWidth?.toInt(),
      maxHeight: maxHeight?.toInt(),
      imageQuality: imageQuality,
    );
  }

  /// 从相机拍照（Web端）
  /// 
  /// 注意：Web端通常不支持直接调用相机，会回退到图库选择
  static Future<XFile?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebImagePickerAdapter 仅支持 Web 平台');
    }

    // Web端相机功能受限，回退到图库
    return await pickImageFromGallery(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// 选择多个图片（Web端）
  /// 
  /// [maxWidth] 最大宽度
  /// [maxHeight] 最大高度
  /// [imageQuality] 图片质量（0-100）
  static Future<List<XFile>> pickMultipleImages({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebImagePickerAdapter 仅支持 Web 平台');
    }

    return await WebFileAdapter.pickMultipleImages(
      maxWidth: maxWidth?.toInt(),
      maxHeight: maxHeight?.toInt(),
      imageQuality: imageQuality,
    );
  }

  /// 选择视频（Web端）
  /// 
  /// [source] 视频来源（图库或相机）
  static Future<XFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebImagePickerAdapter 仅支持 Web 平台');
    }

    // Web端使用文件适配器选择视频
    return await WebFileAdapter.pickFile(
      accept: 'video/*',
      multiple: false,
    );
  }

  /// 检查是否支持相机
  /// 
  /// Web端通常不支持直接调用相机
  static bool get isCameraAvailable {
    if (!kIsWeb) return false;
    // Web端相机支持有限，返回false
    return false;
  }

  /// 检查是否支持图库
  /// 
  /// Web端通常支持图库选择
  static bool get isGalleryAvailable {
    if (!kIsWeb) return false;
    return true;
  }
}
