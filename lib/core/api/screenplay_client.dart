import 'api_client.dart';
import '../../features/screenplay/models/screenplay.dart';
import '../../features/screenplay/models/scene.dart';
import '../../features/screenplay/models/character_sheet.dart';
import 'conversation_client.dart' show PaginatedResponse;

/// 剧本客户端
class ScreenplayClient {
  final ApiClient _apiClient;

  ScreenplayClient(this._apiClient);

  /// 生成剧本草稿
  /// 
  /// [taskId] 任务ID
  /// [prompt] 用户提示词
  /// [userImages] 用户上传的参考图片（base64编码）
  /// [sceneCount] 场景数量
  /// [characterCount] 角色数量
  Future<Screenplay> createDraft({
    required String taskId,
    required String prompt,
    List<String>? userImages,
    int sceneCount = 7,
    int characterCount = 2,
  }) async {
    final response = await _apiClient.post(
      '/screenplays/draft',
      data: {
        'taskId': taskId,
        'prompt': prompt,
        if (userImages != null) 'userImages': userImages,
        'sceneCount': sceneCount,
        'characterCount': characterCount,
      },
    );
    return Screenplay.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 确认剧本
  /// 
  /// [id] 剧本ID
  /// [feedback] 用户反馈（可选）
  Future<Screenplay> confirmScreenplay(
    String id, {
    String? feedback,
  }) async {
    final response = await _apiClient.post(
      '/screenplays/$id/confirm',
      data: {
        if (feedback != null) 'feedback': feedback,
      },
    );
    return Screenplay.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 获取剧本详情
  /// 
  /// [id] 剧本ID
  Future<Screenplay> getScreenplay(String id) async {
    final response = await _apiClient.get('/screenplays/$id');
    return Screenplay.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 更新剧本
  /// 
  /// [id] 剧本ID
  /// [data] 更新数据
  Future<Screenplay> updateScreenplay(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _apiClient.put(
      '/screenplays/$id',
      data: data,
    );
    return Screenplay.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// 获取剧本列表
  /// 
  /// [page] 页码
  /// [pageSize] 每页数量
  /// [taskId] 任务ID（可选，用于筛选）
  Future<PaginatedResponse<Screenplay>> getScreenplays({
    int page = 1,
    int pageSize = 20,
    String? taskId,
  }) async {
    final response = await _apiClient.get(
      '/screenplays',
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
        if (taskId != null) 'taskId': taskId,
      },
    );
    return PaginatedResponse.fromJson(
      response.data['data'] as Map<String, dynamic>,
      (json) => Screenplay.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 删除剧本
  /// 
  /// [id] 剧本ID
  Future<void> deleteScreenplay(String id) async {
    await _apiClient.delete('/screenplays/$id');
  }
}
