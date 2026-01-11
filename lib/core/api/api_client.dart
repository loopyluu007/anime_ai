import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// API客户端基类
class ApiClient {
  late Dio _dio;
  final Future<String?> Function()? getToken;

  ApiClient({this.getToken}) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: Duration(seconds: ApiConfig.connectTimeout),
      receiveTimeout: Duration(seconds: ApiConfig.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 添加请求拦截器（添加 Token）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (getToken != null) {
          final token = await getToken!();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // 处理 401 错误（Token 过期）
        if (error.response?.statusCode == 401) {
          // Token过期，可以在这里触发登出
        }
        return handler.next(error);
      },
    ));

    // 添加日志拦截器（开发环境）
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        return ApiException(
          code: data['code'] ?? error.response!.statusCode ?? 0,
          message: data['message'] ?? '请求失败',
          error: data['error'],
        );
      } else {
        return ApiException(
          code: 0,
          message: error.message ?? '网络错误',
        );
      }
    }
    return ApiException(code: 0, message: error.toString());
  }
}

/// API 异常
class ApiException implements Exception {
  final int code;
  final String message;
  final dynamic error;

  ApiException({
    required this.code,
    required this.message,
    this.error,
  });

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}
