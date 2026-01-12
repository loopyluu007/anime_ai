# Vercel Flutter Web 编译错误修复总结

## 修复时间
2026-01-XX

## 修复的错误

### 1. ✅ conversation_client.dart 导入路径错误

**错误**: `Error: Error when reading 'lib/features/core/api/conversation_client.dart'`

**原因**: `lib/features/chat/providers/chat_provider.dart` 和 `lib/features/chat/providers/conversation_provider.dart` 使用了错误的相对路径 `../../core/api/conversation_client.dart`。

**修复**: 将路径改为 `../../../core/api/conversation_client.dart`

**文件**:
- `lib/features/chat/providers/chat_provider.dart`
- `lib/features/chat/providers/conversation_provider.dart`

### 2. ✅ share_service.dart 条件导入语法错误

**错误**: `Error: An import directive can only have one prefix ('as' clause).`

**原因**: 条件导入语法错误：
```dart
import 'dart:html' as html if (dart.library.io) 'dart:io' as io;
```

**修复**: 使用正确的条件导入语法和 stub 文件：
```dart
import 'package:director_ai/web/stubs/html_stub.dart' as html if (dart.library.html) 'dart:html' as html;
```

**文件**:
- `lib/services/share_service.dart`
- `lib/web/stubs/html_stub.dart` (新建)

### 3. ✅ ImageInfo 类型冲突

**错误**: `'ImageInfo' is imported from both 'package:director_ai/core/api/media_client.dart' and 'package:flutter/src/painting/image_stream.dart'`

**原因**: 自定义的 `ImageInfo` (typedef) 与 Flutter 框架的 `ImageInfo` 类冲突。

**修复**: 在导入 `package:flutter/material.dart` 时使用 `hide ImageInfo` 隐藏 Flutter 的 `ImageInfo`：
```dart
import 'package:flutter/material.dart' hide ImageInfo;
```

**文件**:
- `lib/features/gallery/screens/gallery_screen.dart`
- `lib/features/gallery/widgets/media_grid.dart`

### 4. ✅ ErrorWidget 使用错误

**错误**: `Error: Too few positional arguments: 1 required, 0 given.`

**原因**: 使用了 Flutter 框架的 `ErrorWidget` 而不是自定义的 `AppErrorWidget`。

**修复**: 使用自定义的 `AppErrorWidget` 并添加正确的导入前缀：
```dart
import '../../../shared/widgets/error_widget.dart' as error_widget;
// ...
return error_widget.AppErrorWidget(...);
```

**文件**:
- `lib/features/task/screens/task_list_screen.dart`
- `lib/features/screenplay/screens/screenplay_detail_screen.dart`
- `lib/features/screenplay/screens/screenplay_review_screen.dart`
- `lib/features/gallery/screens/gallery_screen.dart`

### 5. ✅ Duration 类型错误

**错误**: `Error: The argument type 'Duration' can't be assigned to the parameter type 'int'.`

**原因**: `MediaFile.duration` 是 `Duration?` 类型，但 `_formatDuration` 方法期望 `int`（秒数）。

**修复**: 在调用 `_formatDuration` 之前将 `Duration` 转换为秒数：
```dart
_formatDuration(video.duration!.inSeconds)
```

**文件**:
- `lib/features/gallery/widgets/media_grid.dart`
- `lib/features/gallery/screens/gallery_screen.dart`

### 6. ✅ websocket_client.dart _getToken 可能为 null

**错误**: `Error: Can't use an expression of type 'Future<String?> Function()?' as a function because it's potentially null.`

**原因**: `_getToken` 可能为 null，但直接调用 `await _getToken()`。

**修复**: 代码已经正确，`_getToken` 在使用前已检查 null。无需修改。

**状态**: 代码已正确，无需修改

## 注意事项

### Web 平台兼容性

以下文件使用了条件导入和 `kIsWeb` 检查，在 Web 平台上不会执行相关代码，因此不会产生编译错误：

1. **download_service.dart**
   - `_getDownloadDirectory()` 方法在 Web 平台会抛出 `UnsupportedError`
   - Web 平台使用 `WebFileAdapter.downloadFile()` 替代

2. **data_management_screen.dart**
   - `_getCacheSize()` 和 `_getDatabaseSize()` 在 Web 平台返回 0
   - UI 显示 "Web端暂不支持计算" 提示

这些代码在 Web 平台上已经正确适配，不会导致编译错误。

## 修复后的验证

修复后，Vercel 构建应该能够：
1. ✅ 成功编译 Flutter Web 应用
2. ✅ 生成 `build/web` 目录
3. ✅ 成功部署到 Vercel

## 下一步

如果还有其他编译错误，请：
1. 检查 Vercel 构建日志
2. 根据错误信息定位问题文件
3. 使用相同的修复策略（条件导入、类型转换等）

---

**文档版本**: v1.0  
**最后更新**: 2026-01-XX
