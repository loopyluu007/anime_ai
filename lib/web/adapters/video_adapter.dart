import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// 视频适配器（跨平台）
/// 根据平台自动选择相应的实现
class VideoAdapter {
  /// 检查视频格式是否支持
  static bool isSupportedFormat(String url) {
    if (kIsWeb) {
      return WebVideoAdapter.isValidDataSource(url);
    } else {
      // 移动端支持更多格式
      return url.isNotEmpty;
    }
  }

  /// 创建视频控制器
  static Future<VideoPlayerController> createController(String url) async {
    if (kIsWeb) {
      return await WebVideoAdapter.createController(dataSource: url);
    } else {
      // 移动端：根据 URL 类型创建控制器
      VideoPlayerController controller;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(url));
      } else {
        // 本地文件
        controller = VideoPlayerController.asset(url);
      }
      await controller.initialize();
      return controller;
    }
  }
}

/// Web 视频播放器适配器
/// 提供Web平台特定的视频播放实现
class WebVideoAdapter {
  /// 创建视频控制器（Web 端）
  /// 
  /// [dataSource] 视频数据源，Web端只支持网络URL
  /// [options] 视频播放器选项
  static Future<VideoPlayerController> createController({
    required String dataSource,
    VideoPlayerOptions? options,
  }) async {
    if (!kIsWeb) {
      throw UnsupportedError('WebVideoAdapter 仅支持 Web 平台');
    }

    // Web 端：只能使用网络 URL
    if (!dataSource.startsWith('http://') && 
        !dataSource.startsWith('https://')) {
      throw ArgumentError('Web 端只支持网络 URL，当前数据源: $dataSource');
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(dataSource),
      videoPlayerOptions: options ?? VideoPlayerOptions(),
    );

    await controller.initialize();
    return controller;
  }

  /// 构建 Web 视频播放器 Widget
  static Widget buildPlayer(VideoPlayerController controller) {
    if (!kIsWeb) {
      throw UnsupportedError('WebVideoAdapter 仅支持 Web 平台');
    }
    return _WebVideoPlayer(controller: controller);
  }

  /// 检查数据源是否有效（Web端）
  static bool isValidDataSource(String dataSource) {
    if (!kIsWeb) {
      return false;
    }
    return dataSource.startsWith('http://') || 
           dataSource.startsWith('https://');
  }
}

/// Web 视频播放器组件
class _WebVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const _WebVideoPlayer({required this.controller});

  @override
  State<_WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<_WebVideoPlayer> {
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.controller.value.isInitialized) {
      setState(() {
        _isInitialized = true;
        _duration = widget.controller.value.duration;
        _position = widget.controller.value.position;
      });
    } else {
      await widget.controller.initialize();
      setState(() {
        _isInitialized = true;
        _duration = widget.controller.value.duration;
        _position = widget.controller.value.position;
      });
    }

    // 监听播放状态
    widget.controller.addListener(_onPlayerStateChanged);
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller.value.isPlaying;
        _position = widget.controller.value.position;
        _duration = widget.controller.value.duration;
      });
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  void _seekTo(Duration position) {
    widget.controller.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        children: [
          // 视频播放器
          Center(
            child: AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            ),
          ),
          // 控制栏
          if (_showControls)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 进度条
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _position.inMilliseconds.toDouble(),
                              min: 0,
                              max: _duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                _seekTo(Duration(milliseconds: value.toInt()));
                              },
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 播放控制按钮
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                            onPressed: _togglePlayPause,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPlayerStateChanged);
    widget.controller.dispose();
    super.dispose();
  }
}
