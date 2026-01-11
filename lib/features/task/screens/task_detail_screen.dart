import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_progress_widget.dart';
import '../../../core/models/task.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/error_widget.dart';
import '../../../shared/utils/date_utils.dart';

/// 任务详情界面
class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTaskDetail(widget.taskId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        actions: [
          // 刷新按钮
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TaskProvider>().refreshCurrentTask();
            },
            tooltip: '刷新',
          ),
          // 更多操作
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              final provider = context.read<TaskProvider>();
              final task = provider.currentTask;
              if (task == null) return;

              switch (value) {
                case 'cancel':
                  if (task.status == TaskStatus.processing ||
                      task.status == TaskStatus.pending) {
                    _showCancelDialog(context, provider, task);
                  }
                  break;
                case 'delete':
                  _showDeleteDialog(context, provider, task);
                  break;
              }
            },
            itemBuilder: (context) {
              final provider = context.read<TaskProvider>();
              final task = provider.currentTask;
              final canCancel = task != null &&
                  (task.status == TaskStatus.processing ||
                      task.status == TaskStatus.pending);

              return [
                if (canCancel)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Row(
                      children: [
                        Icon(Icons.cancel, size: 20),
                        SizedBox(width: 8),
                        Text('取消任务'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除任务', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          // 加载中
          if (provider.isLoadingDetail) {
            return const LoadingIndicator(message: '加载任务详情...');
          }

          // 错误状态
          if (provider.error != null && provider.currentTask == null) {
            return ErrorWidget(
              message: provider.error!,
              onRetry: () {
                provider.clearError();
                provider.loadTaskDetail(widget.taskId);
              },
            );
          }

          final task = provider.currentTask;
          if (task == null) {
            return const Center(child: Text('任务不存在'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 任务进度
                if (provider.currentTaskProgress != null)
                  TaskProgressWidget(
                    progress: provider.currentTaskProgress!,
                    taskStatus: task.status,
                  ),
                const SizedBox(height: 16),
                // 任务基本信息
                _buildInfoCard(
                  context,
                  title: '任务信息',
                  children: [
                    _buildInfoRow(context, '任务ID', task.id),
                    _buildInfoRow(
                      context,
                      '任务类型',
                      _getTypeText(task.type),
                    ),
                    _buildInfoRow(
                      context,
                      '任务状态',
                      _getStatusText(task.status),
                    ),
                    _buildInfoRow(
                      context,
                      '创建时间',
                      DateUtils.formatDateTime(task.createdAt),
                    ),
                    if (task.updatedAt != null)
                      _buildInfoRow(
                        context,
                        '更新时间',
                        DateUtils.formatDateTime(task.updatedAt!),
                      ),
                    if (task.completedAt != null)
                      _buildInfoRow(
                        context,
                        '完成时间',
                        DateUtils.formatDateTime(task.completedAt!),
                      ),
                  ],
                ),
                // 任务参数
                if (task.params.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: '任务参数',
                    children: task.params.entries.map((entry) {
                      return _buildInfoRow(
                        context,
                        entry.key,
                        entry.value.toString(),
                      );
                    }).toList(),
                  ),
                ],
                // 任务结果
                if (task.result != null && task.result!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    context,
                    title: '任务结果',
                    children: task.result!.entries.map((entry) {
                      return _buildInfoRow(
                        context,
                        entry.key,
                        entry.value.toString(),
                      );
                    }).toList(),
                  ),
                ],
                // 错误信息
                if (task.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '错误信息',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeText(TaskType type) {
    switch (type) {
      case TaskType.screenplay:
        return '剧本';
      case TaskType.image:
        return '图片';
      case TaskType.video:
        return '视频';
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '等待中';
      case TaskStatus.processing:
        return '处理中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.failed:
        return '失败';
      case TaskStatus.cancelled:
        return '已取消';
    }
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
                Navigator.pop(context); // 返回任务列表
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
