# 任务模块 (Task Module)

任务模块提供了完整的任务管理功能，包括任务列表、任务详情、任务进度追踪等。

## 📁 目录结构

```
lib/features/task/
├── providers/
│   └── task_provider.dart      # 任务状态管理
├── screens/
│   ├── task_list_screen.dart    # 任务列表页面
│   └── task_detail_screen.dart  # 任务详情页面
├── widgets/
│   ├── task_card.dart           # 任务卡片组件
│   └── task_progress_widget.dart # 任务进度组件
└── README.md                    # 本文档
```

## 🚀 功能特性

### 1. 任务列表 (TaskListScreen)

- ✅ 显示所有任务
- ✅ 支持按类型筛选（剧本/图片/视频）
- ✅ 支持按状态筛选（等待中/处理中/已完成/失败）
- ✅ 下拉刷新
- ✅ 上拉加载更多
- ✅ 任务卡片显示（类型、状态、进度）
- ✅ 取消任务
- ✅ 删除任务

### 2. 任务详情 (TaskDetailScreen)

- ✅ 显示任务详细信息
- ✅ 实时任务进度追踪
- ✅ 任务参数展示
- ✅ 任务结果展示
- ✅ 错误信息展示
- ✅ 手动刷新任务状态
- ✅ 取消/删除任务操作

### 3. 任务状态管理 (TaskProvider)

- ✅ 任务列表管理
- ✅ 任务详情管理
- ✅ 任务进度管理
- ✅ 筛选功能
- ✅ 分页加载
- ✅ WebSocket 集成（可选）

## 📖 使用方法

### 1. 在应用中使用

任务模块已经在 `main.dart` 中注册了 `TaskProvider`，可以直接使用：

```dart
// 访问任务列表
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TaskListScreen(),
  ),
);

// 访问任务详情
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TaskDetailScreen(taskId: 'task_id'),
  ),
);
```

### 2. 使用 TaskProvider

```dart
// 获取 Provider
final taskProvider = context.read<TaskProvider>();

// 加载任务列表
await taskProvider.loadTasks(refresh: true);

// 加载任务详情
await taskProvider.loadTaskDetail('task_id');

// 取消任务
await taskProvider.cancelTask('task_id');

// 删除任务
await taskProvider.deleteTask('task_id');

// 设置筛选条件
taskProvider.setFilters(type: TaskType.screenplay, status: TaskStatus.processing);
```

### 3. 监听任务状态

```dart
Consumer<TaskProvider>(
  builder: (context, provider, child) {
    if (provider.isLoading) {
      return const CircularProgressIndicator();
    }
    
    return ListView.builder(
      itemCount: provider.tasks.length,
      itemBuilder: (context, index) {
        final task = provider.tasks[index];
        return TaskCard(task: task);
      },
    );
  },
)
```

## 🎨 组件说明

### TaskCard

任务卡片组件，用于在列表中显示任务信息。

**属性：**
- `task` (Task) - 任务对象
- `onTap` (VoidCallback?) - 点击回调
- `onCancel` (VoidCallback?) - 取消任务回调
- `onDelete` (VoidCallback?) - 删除任务回调

**示例：**
```dart
TaskCard(
  task: task,
  onTap: () => Navigator.push(...),
  onCancel: () => _cancelTask(task.id),
  onDelete: () => _deleteTask(task.id),
)
```

### TaskProgressWidget

任务进度组件，用于显示任务的实时进度。

**属性：**
- `progress` (TaskProgress) - 任务进度对象
- `taskStatus` (TaskStatus) - 任务状态

**示例：**
```dart
TaskProgressWidget(
  progress: taskProgress,
  taskStatus: task.status,
)
```

## 🔌 API 集成

任务模块使用 `TaskClient` 与后端 API 通信：

- `GET /tasks` - 获取任务列表
- `GET /tasks/{id}` - 获取任务详情
- `GET /tasks/{id}/progress` - 获取任务进度
- `POST /tasks/{id}/cancel` - 取消任务
- `DELETE /tasks/{id}` - 删除任务

## 📝 任务类型

- `TaskType.screenplay` - 剧本任务
- `TaskType.image` - 图片任务
- `TaskType.video` - 视频任务

## 📊 任务状态

- `TaskStatus.pending` - 等待中
- `TaskStatus.processing` - 处理中
- `TaskStatus.completed` - 已完成
- `TaskStatus.failed` - 失败
- `TaskStatus.cancelled` - 已取消

## 🔄 WebSocket 集成

任务模块支持通过 WebSocket 接收实时更新：

```dart
// 在 TaskProvider 中设置 WebSocket Provider
taskProvider.setWebSocketProvider(webSocketProvider);

// WebSocket 事件会自动更新任务状态
// - task.progress - 任务进度更新
// - task.completed - 任务完成
// - task.failed - 任务失败
```

## 🎯 后续优化

- [ ] 添加任务搜索功能
- [ ] 添加任务排序功能
- [ ] 优化任务进度动画
- [ ] 添加任务批量操作
- [ ] 添加任务导出功能
- [ ] 优化错误处理和重试机制

---

**最后更新**: 2026-01-12
