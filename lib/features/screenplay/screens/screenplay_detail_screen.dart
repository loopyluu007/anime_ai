import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/screenplay_provider.dart';
import '../widgets/scene_card.dart';
import '../widgets/character_sheet_card.dart';
import '../widgets/progress_indicator.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';

class ScreenplayDetailScreen extends StatefulWidget {
  final String screenplayId;
  
  const ScreenplayDetailScreen({
    super.key,
    required this.screenplayId,
  });

  @override
  State<ScreenplayDetailScreen> createState() => _ScreenplayDetailScreenState();
}

class _ScreenplayDetailScreenState extends State<ScreenplayDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScreenplay();
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('剧本详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScreenplay,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<ScreenplayProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentScreenplay == null) {
            return const LoadingIndicator(message: '加载剧本中...');
          }

          if (provider.error != null && provider.currentScreenplay == null) {
            return ErrorWidget(
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
              // 标题和状态卡片
              Container(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                screenplay.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            Chip(
                              label: Text(_getStatusText(screenplay.status)),
                              avatar: Icon(
                                _getStatusIcon(screenplay.status),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildInfoChip(
                              context,
                              Icons.movie,
                              '${screenplay.scenes.length} 场景',
                            ),
                            const SizedBox(width: 8),
                            if (screenplay.characterSheets.isNotEmpty)
                              _buildInfoChip(
                                context,
                                Icons.people,
                                '${screenplay.characterSheets.length} 角色',
                              ),
                            const Spacer(),
                            Text(
                              '创建于 ${_formatDate(screenplay.createdAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Tab栏
              DefaultTabController(
                length: 2,
                child: Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        tabs: const [
                          Tab(text: '场景', icon: Icon(Icons.movie)),
                          Tab(text: '角色', icon: Icon(Icons.people)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 场景列表
                            screenplay.scenes.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.movie_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '暂无场景',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadScreenplay,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: screenplay.scenes.length,
                                      itemBuilder: (context, index) {
                                        return SceneCard(
                                          scene: screenplay.scenes[index],
                                        );
                                      },
                                    ),
                                  ),
                            // 角色列表
                            screenplay.characterSheets.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '暂无角色',
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadScreenplay,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: screenplay.characterSheets.length,
                                      itemBuilder: (context, index) {
                                        return CharacterSheetCard(
                                          character: screenplay.characterSheets[index],
                                        );
                                      },
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

