import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../widgets/media_grid.dart';
import '../../../core/api/media_client.dart' show ImageInfo, VideoInfo, MediaFile;
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart' as error_widget;
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/video_player.dart';
import '../../../services/download_service.dart';
import '../../../services/share_service.dart';

/// 图库界面
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});
  
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final DownloadService _downloadService = DownloadService();
  final ShareService _shareService = ShareService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);
    
    // 加载数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadMedia();
    });
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final provider = context.read<GalleryProvider>();
      switch (_tabController.index) {
        case 0:
          provider.setType(GalleryType.all);
          break;
        case 1:
          provider.setType(GalleryType.images);
          break;
        case 2:
          provider.setType(GalleryType.videos);
          break;
      }
    }
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 接近底部时加载更多
      final provider = context.read<GalleryProvider>();
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMore();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图库'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '图片'),
            Tab(text: '视频'),
          ],
        ),
      ),
      body: Consumer<GalleryProvider>(
        builder: (context, provider, child) {
          // 错误状态
          if (provider.error != null && provider.images.isEmpty && provider.videos.isEmpty) {
            return error_widget.ErrorWidget(
              message: provider.error!,
              onRetry: () => provider.refresh(),
            );
          }
          
          // 加载状态
          if (provider.isLoading && provider.images.isEmpty && provider.videos.isEmpty) {
            return const LoadingIndicator();
          }
          
          // 空状态
          if (provider.images.isEmpty && provider.videos.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: EmptyState(
                    message: _getEmptyMessage(provider.currentType),
                    icon: _getEmptyIcon(provider.currentType),
                    action: ElevatedButton.icon(
                      onPressed: () => provider.refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('刷新'),
                    ),
                  ),
                ),
              ),
            );
          }
          
          // 内容
          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 媒体网格
                SliverToBoxAdapter(
                  child: MediaGrid(
                    images: provider.currentType == GalleryType.all || 
                            provider.currentType == GalleryType.images
                        ? provider.images
                        : [],
                    videos: provider.currentType == GalleryType.all || 
                            provider.currentType == GalleryType.videos
                        ? provider.videos
                        : [],
                    onImageTap: (image) => _showImageDetail(context, image),
                    onVideoTap: (video) => _showVideoDetail(context, video),
                    onImageLongPress: (image) => _showImageOptions(context, image),
                    onVideoLongPress: (video) => _showVideoOptions(context, video),
                  ),
                ),
                // 加载更多指示器
                if (provider.isLoadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                // 底部间距
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _getEmptyMessage(GalleryType type) {
    switch (type) {
      case GalleryType.all:
        return '还没有任何媒体文件';
      case GalleryType.images:
        return '还没有图片';
      case GalleryType.videos:
        return '还没有视频';
    }
  }
  
  IconData _getEmptyIcon(GalleryType type) {
    switch (type) {
      case GalleryType.all:
        return Icons.photo_library_outlined;
      case GalleryType.images:
        return Icons.image_outlined;
      case GalleryType.videos:
        return Icons.video_library_outlined;
    }
  }
  
  void _showImageDetail(BuildContext context, ImageInfo image) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ImageDetailScreen(image: image),
      ),
    );
  }
  
  void _showVideoDetail(BuildContext context, VideoInfo video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _VideoDetailScreen(video: video),
      ),
    );
  }
  
  void _showImageOptions(BuildContext context, ImageInfo image) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('下载'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现下载功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('下载功能开发中')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 实现分享功能
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('分享功能开发中')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteImage(context, image);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showVideoOptions(BuildContext context, VideoInfo video) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('下载'),
              onTap: () {
                Navigator.pop(context);
                _downloadVideo(context, video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () {
                Navigator.pop(context);
                _shareVideo(context, video);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('删除', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteVideo(context, video);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _deleteImage(BuildContext context, ImageInfo image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这张图片吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final provider = context.read<GalleryProvider>();
      try {
        await provider.deleteImage(image.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }
  
  Future<void> _deleteVideo(BuildContext context, VideoInfo video) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个视频吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final provider = context.read<GalleryProvider>();
      try {
        await provider.deleteVideo(video.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: $e')),
          );
        }
      }
    }
  }

  /// 下载图片
  Future<void> _downloadImage(BuildContext context, ImageInfo image) async {
    try {
      // 显示加载提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('正在下载...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 生成文件名
      final extension = image.url.contains('.png') ? '.png' : 
                       image.url.contains('.jpg') || image.url.contains('.jpeg') ? '.jpg' : '.jpg';
      final filename = 'image_${image.id}$extension';

      // 下载文件
      await _downloadService.downloadFile(
        image.url,
        filename: filename,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  /// 分享图片
  Future<void> _shareImage(BuildContext context, ImageInfo image) async {
    try {
      await _shareService.shareUrl(image.url, title: '分享图片');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接已复制到剪贴板')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  /// 下载视频
  Future<void> _downloadVideo(BuildContext context, VideoInfo video) async {
    if (video.status != 'completed' || video.url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('视频尚未就绪，无法下载')),
        );
      }
      return;
    }

    try {
      // 显示加载提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('正在下载...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 生成文件名
      final extension = video.url.contains('.mp4') ? '.mp4' : 
                       video.url.contains('.mov') ? '.mov' : '.mp4';
      final filename = 'video_${video.id}$extension';

      // 下载文件
      await _downloadService.downloadFile(
        video.url,
        filename: filename,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    }
  }

  /// 分享视频
  Future<void> _shareVideo(BuildContext context, VideoInfo video) async {
    if (video.status != 'completed' || video.url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('视频尚未就绪，无法分享')),
        );
      }
      return;
    }

    try {
      await _shareService.shareUrl(video.url, title: '分享视频');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接已复制到剪贴板')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }
}

/// 图片详情界面
class _ImageDetailScreen extends StatelessWidget {
  final ImageInfo image;
  
  const _ImageDetailScreen({required this.image});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片详情'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            image.url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.broken_image, size: 64),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 视频详情界面
class _VideoDetailScreen extends StatelessWidget {
  final VideoInfo video;
  
  const _VideoDetailScreen({required this.video});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频详情'),
      ),
      body: video.status == 'completed' && video.url.isNotEmpty
          ? VideoPlayerWidget(
              videoUrl: video.url,
              autoPlay: false,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (video.status == 'processing')
                    const CircularProgressIndicator()
                  else
                    const Icon(Icons.error_outline, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    video.status == 'processing'
                        ? '视频处理中...'
                        : video.status == 'failed'
                            ? '视频生成失败'
                            : '视频未就绪',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (video.duration != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '时长: ${_formatDuration(video.duration!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
    return '0:${secs.toString().padLeft(2, '0')}';
  }
}
