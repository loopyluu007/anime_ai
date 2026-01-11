import 'package:flutter/material.dart';
import '../../../core/models/task.dart';

/// 任务进度组件
class TaskProgressWidget extends StatelessWidget {
  final TaskProgress progress;
  final TaskStatus taskStatus;

  const TaskProgressWidget({
    Key? key,
    required this.progress,
    required this.taskStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(
                _getStatusIcon(),
                size: 20,
                color: _getStatusColor(theme),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${progress.progress}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _getStatusColor(theme),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.progress / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getStatusColor(theme),
              ),
            ),
          ),
          // 当前步骤
          if (progress.currentStep != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress.currentStep!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          // 详细信息
          if (progress.details != null && progress.details!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...progress.details!.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.value.toString(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (taskStatus) {
      case TaskStatus.pending:
        return '等待处理';
      case TaskStatus.processing:
        return '处理中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.failed:
        return '处理失败';
      case TaskStatus.cancelled:
        return '已取消';
    }
  }

  IconData _getStatusIcon() {
    switch (taskStatus) {
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
    switch (taskStatus) {
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
