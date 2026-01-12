# Vercel Flutter Web 编译错误分析

## 错误总结

Vercel 构建时遇到多个编译错误，主要问题如下：

### 1. 导入路径错误

**错误**: `Error: Error when reading 'lib/features/core/api/conversation_client.dart'`

**原因**: `lib/features/chat/providers/chat_provider.dart` 和 `lib/features/chat/providers/conversation_provider.dart` 使用了错误的相对路径 `../../core/api/conversation_client.dart`，实际应该是 `../../../core/api/conversation_client.dart`。

**解决方案**: ✅ 已修复 - 将路径改为 `../../../core/api/conversation_client.dart`

### 2. 条件导入语法错误

**错误**: `Error: An import directive can only have one prefix ('as' clause).`

**文件**: `lib/services/share_service.dart:6`

**原因**: 条件导入语法错误：
```dart
import 'dart:html' as html if (dart.library.io) 'dart:io' as io;
```
这个语法有两个 `as` 子句，不符合 Dart 语法。

**解决方案**: 
- 方案1（推荐）：只导入 `dart:html`，因为代码中只在 Web 端使用 `html`，非 Web 端不执行相关代码
- 方案2：使用 stub 文件进行条件导入

### 3. ImageInfo 类型冲突

**错误**: `'ImageInfo' is imported from both 'package:director_ai/core/api/media_client.dart' and 'package:flutter/src/painting/image_stream.dart'`

**原因**: `lib/core/api/media_client.dart` 中定义了 `typedef ImageInfo = MediaFile;`，但 Flutter 框架中也有 `ImageInfo` 类，在 `lib/features/gallery/screens/gallery_screen.dart` 中使用 `show ImageInfo` 时导致冲突。

**解决方案**: 
- 重命名自定义的 `ImageInfo` 为 `MediaImageInfo` 或其他名称
- 或者使用 `hide ImageInfo` 隐藏 Flutter 的 `ImageInfo`

### 4. ErrorWidget 使用错误

**错误**: `Error: Too few positional arguments: 1 required, 0 given.`

**文件**: `lib/features/task/screens/task_list_screen.dart`, `lib/features/screenplay/screens/screenplay_detail_screen.dart`, `lib/features/screenplay/screens/screenplay_review_screen.dart`

**原因**: 这些文件使用了 `ErrorWidget(...)`，但 Flutter 框架的 `ErrorWidget` 构造函数需要一个参数 `Object exception`，而不是 `message` 和 `onRetry`。

**解决方案**: 使用自定义的 `AppErrorWidget` 而不是 Flutter 的 `ErrorWidget`

### 5. Duration 类型错误

**错误**: `Error: The argument type 'Duration' can't be assigned to the parameter type 'int'.`

**原因**: `MediaFile.duration` 是 `Duration?` 类型，但 `_formatDuration` 方法期望 `int`（秒数）。

**解决方案**: 在调用 `_formatDuration` 之前将 `Duration` 转换为秒数：`video.duration!.inSeconds`

### 6. 其他 Web 平台兼容性问题

- `dart:io` 在 Web 平台不可用
- `Directory`、`File` 等类型在 Web 平台不可用
- `Platform.isAndroid` 等在 Web 平台不可用

**解决方案**: 使用条件导入和 `kIsWeb` 进行平台判断

---

**文档版本**: v1.0  
**最后更新**: 2026-01-XX
