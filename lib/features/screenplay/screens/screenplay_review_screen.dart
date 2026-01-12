import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/screenplay_provider.dart';
import '../widgets/scene_card.dart';
import '../widgets/character_sheet_card.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart' as error_widget;
import 'screenplay_detail_screen.dart';

class ScreenplayReviewScreen extends StatefulWidget {
  final String screenplayId;
  
  const ScreenplayReviewScreen({
    super.key,
    required this.screenplayId,
  });
  
  @override
  State<ScreenplayReviewScreen> createState() => _ScreenplayReviewScreenState();
}

class _ScreenplayReviewScreenState extends State<ScreenplayReviewScreen> {
  final _feedbackController = TextEditingController();
  bool _isConfirming = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadScreenplay() async {
    final provider = Provider.of<ScreenplayProvider>(context, listen: false);
    try {
      await provider.getScreenplay(widget.screenplayId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScreenplay();
    });
  }

  Future<void> _confirmScreenplay() async {
    if (_isConfirming) return;

    setState(() {
      _isConfirming = true;
    });

    final provider = Provider.of<ScreenplayProvider>(context, listen: false);
    try {
      await provider.confirmScreenplay(
        widget.screenplayId,
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ScreenplayDetailScreen(
              screenplayId: widget.screenplayId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('确认失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('剧本预览'),
      ),
      body: Consumer<ScreenplayProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentScreenplay == null) {
            return const LoadingIndicator(message: '加载剧本中...');
          }

          if (provider.error != null && provider.currentScreenplay == null) {
            return error_widget.AppErrorWidget(
              message: provider.error!,
              onRetry: _loadScreenplay,
            );
          }

          final screenplay = provider.currentScreenplay;
          if (screenplay == null) {
            return const Center(child: Text('未找到剧本'));
          }

          return Column(
            children: [
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      // 标题卡片
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  screenplay.title,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(_getStatusText(screenplay.status)),
                                      avatar: Icon(
                                        _getStatusIcon(screenplay.status),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${screenplay.scenes.length} 个场景',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    if (screenplay.characterSheets.isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${screenplay.characterSheets.length} 个角色',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Tab栏
                      TabBar(
                        tabs: const [
                          Tab(text: '场景', icon: Icon(Icons.movie)),
                          Tab(text: '角色', icon: Icon(Icons.people)),
                        ],
                      ),
                      // Tab内容
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 场景列表
                            screenplay.scenes.isEmpty
                                ? Center(
                                    child: Text(
                                      '暂无场景',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: screenplay.scenes.length,
                                    itemBuilder: (context, index) {
                                      return SceneCard(
                                        scene: screenplay.scenes[index],
                                      );
                                    },
                                  ),
                            // 角色列表
                            screenplay.characterSheets.isEmpty
                                ? Center(
                                    child: Text(
                                      '暂无角色',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: screenplay.characterSheets.length,
                                    itemBuilder: (context, index) {
                                      return CharacterSheetCard(
                                        character: screenplay.characterSheets[index],
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 底部操作栏
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _feedbackController,
                      decoration: const InputDecoration(
                        hintText: '反馈意见（可选）',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isConfirming ? null : _confirmScreenplay,
                        child: _isConfirming
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('确认剧本'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getStatusText(screenplayStatus) {
    switch (screenplayStatus.toString().split('.').last) {
      case 'draft':
        return '草稿';
      case 'confirmed':
        return '已确认';
      case 'generating':
        return '生成中';
      case 'completed':
        return '已完成';
      case 'failed':
        return '失败';
      default:
        return '未知';
    }
  }

  IconData _getStatusIcon(screenplayStatus) {
    switch (screenplayStatus.toString().split('.').last) {
      case 'draft':
        return Icons.edit;
      case 'confirmed':
        return Icons.check_circle;
      case 'generating':
        return Icons.autorenew;
      case 'completed':
        return Icons.check_circle_outline;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }
}

