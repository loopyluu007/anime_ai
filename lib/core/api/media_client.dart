// 条件导入：Web端使用dart:html，移动端使用dart:io
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'api_client.dart';
import '../config/api_config.dart';
import 'conversation_client.dart' show PaginatedResponse;

/// 媒体文件信息
class MediaFile {
  final String id;
  final String url;
  final int? size;
  final int? width;
  final int? height;
  final String? mimeType;
  final String status;
  final DateTime createdAt;

  MediaFile({
    required this.id,
    required this.url,
    this.size,
    this.width,
    this.height,
    this.mimeType,
    required this.status,
    required this.createdAt,
  });

  factory MediaFile.fromJson(Map<String, dynamic> json) {
    return MediaFile(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? '',
      size: json['size'],
      width: json['width'],
      height: json['height'],
      mimeType: json['mimeType'] ?? json['mime_type'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'size': size,
      'width': width,
      'height': height,
      'mimeType': mimeType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// 媒体生成任务
class MediaTask {
  final String taskId;
  final String status;
  final String? mediaId;
  final String? errorMessage;
  final DateTime createdAt;

  MediaTask({
    required this.taskId,
    required this.status,
    this.mediaId,
    this.errorMessage,
    required this.createdAt,
  });

  factory MediaTask.fromJson(Map<String, dynamic> json) {
    return MediaTask(
      taskId: json['taskId']?.toString() ?? json['task_id']?.toString() ?? '',
      status: json['status'] ?? 'pending',
      mediaId: json['mediaId']?.toString() ?? json['media_id']?.toString(),
      errorMessage: json['errorMessage'] ?? json['error_message'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
    );
  }
}

/// 媒体客户端
class MediaClient {
  final ApiClient _apiClient;
  late Dio _dio;

  MediaClient(this._apiClient) {
    // 创建用于文件上传的 Dio 实例
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
    ));
    
    // 添加请求拦截器（添加 Token）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_apiClient.getToken != null) {
          final token = await _apiClient.getToken!();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
    ));
  }

  /// 上传图片
  /// 
  /// [file] 图片文件
  /// [type] 图片类型（reference | character）
  Future<MediaFile> uploadImage({
    required XFile file,
    String type = 'reference',
  }) async {
    MultipartFile multipartFile;
    
    if (kIsWeb) {
      // Web端：使用字节数据创建MultipartFile
      final bytes = await file.readAsBytes();
      multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: file.name,
      );
    } else {
      // 移动端：使用文件路径创建MultipartFile
      multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
      );
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
      'type': type,
    });

    final response = await _dio.post(
      '/media/images/upload',
      data: formData,
    );

    return MediaFile.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 生成图片（异步）
  /// 
  /// [prompt] 图片生成提示词
  /// [model] 模型名称
  /// [size] 图片尺寸
  /// [referenceImages] 参考图片ID列表
  Future<MediaTask> generateImage({
    required String prompt,
    String model = 'gemini-3-pro-image-preview-hd',
    String size = '1024x1024',
    List<String>? referenceImages,
  }) async {
    final response = await _apiClient.post(
      '/media/images/generate',
      data: {
        'prompt': prompt,
        'model': model,
        'size': size,
        if (referenceImages != null) 'referenceImages': referenceImages,
      },
    );
    return MediaTask.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 获取生成的图片
  /// 
  /// [id] 图片ID或任务ID
  Future<MediaFile> getImage(String id) async {
    final response = await _apiClient.get('/media/images/$id');
    return MediaFile.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 生成视频（异步）
  /// 
  /// [imageId] 参考图片ID
  /// [prompt] 视频生成提示词
  /// [model] 模型名称
  /// [seconds] 视频时长（秒）
  /// [referenceImages] 参考图片ID列表
  Future<MediaTask> generateVideo({
    required String imageId,
    required String prompt,
    String model = 'sora-1',
    String seconds = '10',
    List<String>? referenceImages,
  }) async {
    final response = await _apiClient.post(
      '/media/videos/generate',
      data: {
        'imageId': imageId,
        'prompt': prompt,
        'model': model,
        'seconds': seconds,
        if (referenceImages != null) 'referenceImages': referenceImages,
      },
    );
    return MediaTask.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 获取生成的视频
  /// 
  /// [id] 视频ID或任务ID
  Future<MediaFile> getVideo(String id) async {
    final response = await _apiClient.get('/media/videos/$id');
    return MediaFile.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 获取媒体文件列表
  /// 
  /// [page] 页码
  /// [pageSize] 每页数量
  /// [type] 文件类型（image | video）
  Future<PaginatedResponse<MediaFile>> getMediaFiles({
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    final response = await _apiClient.get(
      '/media/files',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (type != null) 'type': type,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      (json) => MediaFile.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 删除媒体文件
  /// 
  /// [id] 文件ID
  Future<void> deleteMediaFile(String id) async {
    await _apiClient.delete('/media/files/$id');
  }
}
