import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/media_client.dart';
import '../../../core/storage/local_storage.dart';

/// 图库类型
enum GalleryType {
  all,
  images,
  videos,
}

/// 图库 Provider
class GalleryProvider extends ChangeNotifier {
  final MediaClient _mediaClient;
  
  GalleryType _currentType = GalleryType.all;
  List<ImageInfo> _images = [];
  List<VideoInfo> _videos = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  int _currentPage = 1;
  int _totalImages = 0;
  int _totalVideos = 0;
  bool _hasMoreImages = true;
  bool _hasMoreVideos = true;
  
  GalleryType get currentType => _currentType;
  List<ImageInfo> get images => _images;
  List<VideoInfo> get videos => _videos;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _currentType == GalleryType.all 
      ? (_hasMoreImages || _hasMoreVideos)
      : _currentType == GalleryType.images 
          ? _hasMoreImages 
          : _hasMoreVideos;
  
  GalleryProvider() 
      : _mediaClient = MediaClient(
          ApiClient(
            getToken: () async => await LocalStorage.getString('auth_token'),
          ),
        );
  
  /// 切换图库类型
  void setType(GalleryType type) {
    if (_currentType == type) return;
    _currentType = type;
    _currentPage = 1;
    _images.clear();
    _videos.clear();
    _hasMoreImages = true;
    _hasMoreVideos = true;
    notifyListeners();
    loadMedia();
  }
  
  /// 加载媒体
  Future<void> loadMedia({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _images.clear();
      _videos.clear();
      _hasMoreImages = true;
      _hasMoreVideos = true;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_currentType == GalleryType.all || _currentType == GalleryType.images) {
        await _loadImages();
      }
      if (_currentType == GalleryType.all || _currentType == GalleryType.videos) {
        await _loadVideos();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// 加载更多
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      _currentPage++;
      if (_currentType == GalleryType.all || _currentType == GalleryType.images) {
        await _loadImages();
      }
      if (_currentType == GalleryType.all || _currentType == GalleryType.videos) {
        await _loadVideos();
      }
    } catch (e) {
      _error = e.toString();
      _currentPage--; // 回退页码
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  /// 加载图片
  Future<void> _loadImages() async {
    if (!_hasMoreImages) return;
    
    try {
      final response = await _mediaClient.getImages(
        page: _currentPage,
        pageSize: 20,
      );
      
      _totalImages = response.total;
      _images.addAll(response.items);
      _hasMoreImages = response.items.length == response.pageSize && 
                       _images.length < response.total;
    } catch (e) {
      _hasMoreImages = false;
      rethrow;
    }
  }
  
  /// 加载视频
  Future<void> _loadVideos() async {
    if (!_hasMoreVideos) return;
    
    try {
      final response = await _mediaClient.getVideos(
        page: _currentPage,
        pageSize: 20,
      );
      
      _totalVideos = response.total;
      _videos.addAll(response.items);
      _hasMoreVideos = response.items.length == response.pageSize && 
                       _videos.length < response.total;
    } catch (e) {
      _hasMoreVideos = false;
      rethrow;
    }
  }
  
  /// 删除图片
  Future<void> deleteImage(String id) async {
    try {
      await _mediaClient.deleteImage(id);
      _images.removeWhere((img) => img.id == id);
      _totalImages--;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// 删除视频
  Future<void> deleteVideo(String id) async {
    try {
      await _mediaClient.deleteVideo(id);
      _videos.removeWhere((video) => video.id == id);
      _totalVideos--;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
  
  /// 刷新
  Future<void> refresh() async {
    await loadMedia(refresh: true);
  }
}
