import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../web/adapters/video_adapter.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  
  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  Future<void> _initializePlayer() async {
    try {
      if (!VideoAdapter.isSupportedFormat(widget.videoUrl)) {
        setState(() {
          _error = '不支持的视频格式';
        });
        return;
      }
      
      _controller = await VideoAdapter.createController(widget.videoUrl);
      if (!_controller.value.isInitialized) {
        await _controller.initialize();
      }
      
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _controller.value.aspectRatio,
      );
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = '视频加载失败: $e';
      });
    }
  }
  
  @override
  void dispose() {
    _chewieController?.dispose();
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
          ],
        ),
      );
    }
    
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Chewie(controller: _chewieController!);
  }
}
