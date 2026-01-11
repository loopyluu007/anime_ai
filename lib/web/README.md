# Web适配层文档

> **版本**: v1.0  
> **最后更新**: 2026-01-12

---

## 📋 概述

Web适配层提供了Flutter Web平台特定的实现，包括存储、视频播放、文件操作、响应式布局等功能。

## 📁 目录结构

```
lib/web/
├── adapters/              # Web适配器
│   ├── storage_adapter.dart          # 存储适配器
│   ├── video_adapter.dart            # 视频播放适配器
│   ├── file_adapter.dart             # 文件操作适配器
│   ├── image_picker_adapter.dart     # 图片选择适配器
│   └── __init__.dart                 # 导出文件
├── widgets/               # Web特定组件
│   ├── responsive_layout.dart        # 响应式布局工具
│   └── __init__.dart                 # 导出文件
└── utils/                 # Web工具
    ├── pwa_utils.dart                # PWA工具
    ├── seo_utils.dart                # SEO工具
    └── __init__.dart                 # 导出文件
```

---

## 🔧 适配器使用指南

### 1. 存储适配器 (WebStorageAdapter)

提供Web平台特定的本地存储功能。

**使用示例：**

```dart
import 'package:director_ai/web/adapters/storage_adapter.dart';

// 保存数据
await WebStorageAdapter.setString('key', 'value');
await WebStorageAdapter.setInt('count', 42);
await WebStorageAdapter.setBool('isLoggedIn', true);

// 读取数据
final value = await WebStorageAdapter.getString('key');
final count = await WebStorageAdapter.getInt('count');
final isLoggedIn = await WebStorageAdapter.getBool('isLoggedIn');

// 删除数据
await WebStorageAdapter.remove('key');

// 清空所有数据
await WebStorageAdapter.clear();
```

### 2. 视频适配器 (WebVideoAdapter)

提供Web平台特定的视频播放功能。

**使用示例：**

```dart
import 'package:director_ai/web/adapters/video_adapter.dart';
import 'package:video_player/video_player.dart';

// 创建视频控制器
final controller = await WebVideoAdapter.createController(
  dataSource: 'https://example.com/video.mp4',
);

// 构建视频播放器Widget
final player = WebVideoAdapter.buildPlayer(controller);

// 检查数据源是否有效
if (WebVideoAdapter.isValidDataSource(url)) {
  // 使用URL
}
```

### 3. 文件适配器 (WebFileAdapter)

提供Web平台特定的文件操作功能。

**使用示例：**

```dart
import 'package:director_ai/web/adapters/file_adapter.dart';
import 'package:image_picker/image_picker.dart';

// 选择图片
final image = await WebFileAdapter.pickImage();

// 选择多个图片
final images = await WebFileAdapter.pickMultipleImages();

// 选择文件
final file = await WebFileAdapter.pickFile(accept: 'image/*');

// 下载文件
await WebFileAdapter.downloadFile(
  'https://example.com/file.pdf',
  'document.pdf',
);

// 下载字节数据
await WebFileAdapter.downloadBytes(
  bytes,
  'data.bin',
  mimeType: 'application/octet-stream',
);
```

### 4. 图片选择适配器 (WebImagePickerAdapter)

提供Web平台特定的图片选择功能。

**使用示例：**

```dart
import 'package:director_ai/web/adapters/image_picker_adapter.dart';
import 'package:image_picker/image_picker.dart';

// 从图库选择图片
final image = await WebImagePickerAdapter.pickImageFromGallery(
  maxWidth: 1920,
  maxHeight: 1080,
  imageQuality: 85,
);

// 选择多个图片
final images = await WebImagePickerAdapter.pickMultipleImages();

// 选择视频
final video = await WebImagePickerAdapter.pickVideo();
```

---

## 🎨 响应式布局

### ResponsiveLayout

提供响应式布局工具类。

**使用示例：**

```dart
import 'package:director_ai/web/widgets/responsive_layout.dart';

// 判断设备类型
if (ResponsiveLayout.isMobile(context)) {
  // 移动端逻辑
} else if (ResponsiveLayout.isTablet(context)) {
  // 平板逻辑
} else if (ResponsiveLayout.isDesktop(context)) {
  // 桌面端逻辑
}

// 响应式值
final padding = ResponsiveLayout.responsiveValue(
  context,
  mobile: 16.0,
  tablet: 24.0,
  desktop: 32.0,
);

// 响应式列数
final columns = ResponsiveLayout.responsiveColumns(context);

// 响应式字体大小
final fontSize = ResponsiveLayout.responsiveFontSize(
  context,
  mobile: 14.0,
  tablet: 16.0,
  desktop: 18.0,
);
```

### ResponsiveContainer

响应式容器组件。

**使用示例：**

```dart
import 'package:director_ai/web/widgets/responsive_layout.dart';

ResponsiveContainer(
  maxWidth: 1200,
  padding: EdgeInsets.all(16),
  child: YourWidget(),
)
```

### ResponsiveGridView

响应式网格视图。

**使用示例：**

```dart
import 'package:director_ai/web/widgets/responsive_layout.dart';

ResponsiveGridView(
  children: [
    ItemWidget(),
    ItemWidget(),
    ItemWidget(),
  ],
  crossAxisSpacing: 8.0,
  mainAxisSpacing: 8.0,
  childAspectRatio: 1.0,
)
```

### ResponsiveRow

响应式行布局（移动端垂直，桌面端水平）。

**使用示例：**

```dart
import 'package:director_ai/web/widgets/responsive_layout.dart';

ResponsiveRow(
  children: [
    Widget1(),
    Widget2(),
    Widget3(),
  ],
  spacing: 16.0,
)
```

---

## 🔧 工具类

### PWA工具 (PWAUtils)

提供Progressive Web App相关功能。

**使用示例：**

```dart
import 'package:director_ai/web/utils/pwa_utils.dart';

// 检查是否已安装为PWA
if (PWAUtils.isInstalled) {
  // PWA已安装
}

// 检查是否在线
if (PWAUtils.isOnline) {
  // 在线状态
}

// 监听在线状态变化
PWAUtils.listenOnlineStatus((isOnline) {
  print('在线状态: $isOnline');
});

// 注册Service Worker
await PWAUtils.registerServiceWorker('/sw.js');

// 检查更新
await PWAUtils.checkForUpdate();

// 清除缓存
await PWAUtils.clearCache();
```

### SEO工具 (SEOUtils)

提供搜索引擎优化相关功能。

**使用示例：**

```dart
import 'package:director_ai/web/utils/seo_utils.dart';

// 设置页面标题
SEOUtils.setTitle('AI漫导 - 首页');

// 设置Meta描述
SEOUtils.setMetaDescription('AI漫导是一个AI智能体驱动的短剧制作平台');

// 设置Open Graph标签
SEOUtils.setOpenGraph(
  title: 'AI漫导',
  description: 'AI智能体驱动的短剧制作平台',
  image: 'https://example.com/og-image.jpg',
  url: 'https://example.com',
  type: 'website',
);

// 设置Twitter Card
SEOUtils.setTwitterCard(
  card: 'summary_large_image',
  title: 'AI漫导',
  description: 'AI智能体驱动的短剧制作平台',
  image: 'https://example.com/twitter-image.jpg',
);

// 设置Canonical URL
SEOUtils.setCanonicalUrl('https://example.com/page');
```

---

## ⚠️ 注意事项

1. **平台检查**: 所有适配器都会检查是否在Web平台运行，非Web平台会抛出`UnsupportedError`。

2. **视频播放**: Web端只支持网络URL，不支持本地文件路径。

3. **文件选择**: Web端的文件选择使用HTML5的`<input type="file">`元素，用户体验可能与原生应用不同。

4. **存储限制**: Web端的本地存储（SharedPreferences）有大小限制，通常为5-10MB。

5. **PWA功能**: PWA相关功能需要正确的manifest.json和Service Worker配置。

---

## 🔗 相关文档

- [Web端工程实施方案](../../docs/02-implementation/Web端工程实施方案.md)
- [前端开发文档](../DEVELOPMENT.md)
- [Flutter Web文档](https://docs.flutter.dev/platform-integration/web)

---

**文档版本**: v1.0  
**最后更新**: 2026-01-12  
**维护者**: 开发团队
