import 'package:flutter/material.dart';
import '../../../core/models/task.dart';
import '../../../shared/utils/date_utils.dart' as date_utils;

/// 任务卡片组件
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.onCancel,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 任务类型和状态
              Row(
                children: [
                  _buildTypeChip(context),
                  const Spacer(),
                  _buildStatusChip(context),
                ],
              ),
              const SizedBox(height: 12),
              // 任务信息
              Text(
                _getTaskTitle(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // 进度条
              if (task.status == TaskStatus.processing ||
                  task.status == TaskStatus.pending)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: task.progress / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(theme),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${task.progress}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              // 错误信息
              if (task.status == TaskStatus.failed && task.errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // 时间和操作按钮
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    date_utils.AppDateUtils.formatRelativeTime(task.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  // 操作按钮
                  if (task.status == TaskStatus.processing ||
                      task.status == TaskStatus.pending)
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 20),
                      onPressed: onCancel,
                      tooltip: '取消任务',
                      color: Colors.grey[600],
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: '删除任务',
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final theme = Theme.of(context);
    final typeText = _getTypeText();
    final typeColor = _getTypeColor(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTypeIcon(),
            size: 14,
            color: typeColor,
          ),
          const SizedBox(width: 4),
          Text(
            typeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: typeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final statusText = _getStatusText();
    final statusColor = _getStatusColor(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getTaskTitle() {
    switch (task.type) {
      case TaskType.screenplay:
        return task.params['prompt']?.toString() ?? '生成剧本';
      case TaskType.image:
        return task.params['prompt']?.toString() ?? '生成图片';
      case TaskType.video:
        return task.params['prompt']?.toString() ?? '生成视频';
    }
  }

  String _getTypeText() {
    switch (task.type) {
      case TaskType.screenplay:
        return '剧本';
      case TaskType.image:
        return '图片';
      case TaskType.video:
        return '视频';
    }
  }

  IconData _getTypeIcon() {
    switch (task.type) {
      case TaskType.screenplay:
        return Icons.menu_book;
      case TaskType.image:
        return Icons.image;
      case TaskType.video:
        return Icons.video_library;
    }
  }

  Color _getTypeColor(ThemeData theme) {
    switch (task.type) {
      case TaskType.screenplay:
        return theme.colorScheme.primary;
      case TaskType.image:
        return Colors.blue;
      case TaskType.video:
        return Colors.purple;
    }
  }

  String _getStatusText() {
    switch (task.status) {
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

  IconData _getStatusIcon() {
    switch (task.status) {
      case TaskStatus.pending:
        return Icons.hourglass_empty;
      case TaskStatus.processing:
        return Icons.autorenew;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.failed:
        return Icons.error;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(ThemeData theme) {
    switch (task.status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.processing:
        return theme.colorScheme.primary;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.failed:
        return theme.colorScheme.error;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }
}
