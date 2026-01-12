import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../../../core/models/task.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_widget.dart' as error_widget;
import 'task_detail_screen.dart';

/// 任务列表界面
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // 滚动到80%时加载更多
      final provider = context.read<TaskProvider>();
      if (!provider.isLoading && provider.hasMore) {
        provider.loadTasks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务列表'),
        actions: [
          // 筛选按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              final provider = context.read<TaskProvider>();
              switch (value) {
                case 'all':
                  provider.clearFilters();
                  break;
                case 'screenplay':
                  provider.setFilters(type: TaskType.screenplay);
                  break;
                case 'image':
                  provider.setFilters(type: TaskType.image);
                  break;
                case 'video':
                  provider.setFilters(type: TaskType.video);
                  break;
                case 'pending':
                  provider.setFilters(status: TaskStatus.pending);
                  break;
                case 'processing':
                  provider.setFilters(status: TaskStatus.processing);
                  break;
                case 'completed':
                  provider.setFilters(status: TaskStatus.completed);
                  break;
                case 'failed':
                  provider.setFilters(status: TaskStatus.failed);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('全部任务'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'screenplay',
                child: Text('剧本任务'),
              ),
              const PopupMenuItem(
                value: 'image',
                child: Text('图片任务'),
              ),
              const PopupMenuItem(
                value: 'video',
                child: Text('视频任务'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'pending',
                child: Text('等待中'),
              ),
              const PopupMenuItem(
                value: 'processing',
                child: Text('处理中'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('已完成'),
              ),
              const PopupMenuItem(
                value: 'failed',
                child: Text('失败'),
              ),
            ],
          ),
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TaskProvider>().loadTasks(refresh: true);
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          // 加载中（首次加载）
          if (provider.isLoading && provider.tasks.isEmpty) {
            return const LoadingIndicator(message: '加载任务列表...');
          }

          // 错误状态
          if (provider.error != null && provider.tasks.isEmpty) {
            return error_widget.AppErrorWidget(
              message: provider.error!,
              onRetry: () {
                provider.clearError();
                provider.loadTasks(refresh: true);
              },
            );
          }

          // 空状态
          if (provider.tasks.isEmpty) {
            return EmptyState(
              icon: Icons.task_alt,
              message: '暂无任务\n还没有创建任何任务',
            );
          }

          // 任务列表
          return RefreshIndicator(
            onRefresh: () => provider.loadTasks(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.tasks.length + (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // 加载更多指示器
                if (index >= provider.tasks.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final task = provider.tasks[index];
                return TaskCard(
                  task: task,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(taskId: task.id),
                      ),
                    );
                  },
                  onCancel: () => _showCancelDialog(context, provider, task),
                  onDelete: () => _showDeleteDialog(context, provider, task),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    TaskProvider provider,
    Task task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消任务'),
        content: const Text('确定要取消这个任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.cancelTask(task.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('任务已取消')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? '取消任务失败'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    TaskProvider provider,
    Task task,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: const Text('确定要删除这个任务吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteTask(task.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('任务已删除')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error ?? '删除任务失败'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
