import 'package:flutter/material.dart' hide ImageInfo;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/api/media_client.dart';
import '../../../shared/widgets/loading_indicator.dart';

/// 媒体网格组件
class MediaGrid extends StatelessWidget {
  final List<ImageInfo> images;
  final List<VideoInfo> videos;
  final Function(ImageInfo)? onImageTap;
  final Function(VideoInfo)? onVideoTap;
  final Function(ImageInfo)? onImageLongPress;
  final Function(VideoInfo)? onVideoLongPress;
  final int crossAxisCount;
  final double childAspectRatio;
  final double spacing;
  
  const MediaGrid({
    super.key,
    required this.images,
    required this.videos,
    this.onImageTap,
    this.onVideoTap,
    this.onImageLongPress,
    this.onVideoLongPress,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.spacing = 4.0,
  });
  
  @override
  Widget build(BuildContext context) {
    final allItems = <_MediaItem>[];
    
    // 添加图片
    for (var image in images) {
      allItems.add(_MediaItem(
        type: _MediaType.image,
        image: image,
      ));
    }
    
    // 添加视频
    for (var video in videos) {
      allItems.add(_MediaItem(
        type: _MediaType.video,
        video: video,
      ));
    }
    
    // 按创建时间排序（最新的在前）
    allItems.sort((a, b) {
      final aTime = a.createdAt ?? DateTime(0);
      final bTime = b.createdAt ?? DateTime(0);
      return bTime.compareTo(aTime);
    });
    
    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        if (item.type == _MediaType.image) {
          return _ImageGridItem(
            image: item.image!,
            onTap: () => onImageTap?.call(item.image!),
            onLongPress: () => onImageLongPress?.call(item.image!),
          );
        } else {
          return _VideoGridItem(
            video: item.video!,
            onTap: () => onVideoTap?.call(item.video!),
            onLongPress: () => onVideoLongPress?.call(item.video!),
          );
        }
      },
    );
  }
}

/// 媒体项类型
enum _MediaType {
  image,
  video,
}

/// 媒体项
class _MediaItem {
  final _MediaType type;
  final ImageInfo? image;
  final VideoInfo? video;
  
  _MediaItem({
    required this.type,
    this.image,
    this.video,
  });
  
  DateTime? get createdAt {
    if (type == _MediaType.image) {
      return image?.createdAt;
    } else {
      return video?.createdAt;
    }
  }
}

/// 图片网格项
class _ImageGridItem extends StatelessWidget {
  final ImageInfo image;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  const _ImageGridItem({
    required this.image,
    this.onTap,
    this.onLongPress,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: image.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                ),
              ),
            ),
            // 状态指示器
            if (image.status != null && image.status != 'completed')
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(image.status!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '等待中';
      case 'processing':
        return '处理中';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }
}

/// 视频网格项
class _VideoGridItem extends StatelessWidget {
  final VideoInfo video;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  const _VideoGridItem({
    required this.video,
    this.onTap,
    this.onLongPress,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频缩略图（使用第一帧或占位图）
            Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
            ),
            // 播放按钮覆盖层
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
            // 视频信息
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 时长
                  if (video.duration != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(video.duration!.inSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 状态指示器
            if (video.status != null && video.status != 'completed')
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(video.status!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
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
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '等待中';
      case 'processing':
        return '处理中';
      case 'failed':
        return '失败';
      default:
        return status;
    }
  }
}
