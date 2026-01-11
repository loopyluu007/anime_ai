# Web端平台适配说明

> **最后更新**: 2026-01-12  
> **状态**: 适配进行中

---

## 📋 概述

本文档说明Web端与移动端的差异，以及需要特殊处理的平台特定功能。

---

## 🔧 已适配的功能

### ✅ 完全支持

1. **存储适配**
   - ✅ SharedPreferences → Web LocalStorage
   - ✅ Hive → Web IndexedDB
   - ✅ 文件缓存 → Web缓存API

2. **视频播放**
   - ✅ 网络URL视频播放
   - ✅ HTML5 video播放器
   - ✅ 播放控制（播放/暂停/进度）

3. **文件操作**
   - ✅ 图片选择（文件选择器）
   - ✅ 文件下载（浏览器下载）
   - ✅ Base64转换

4. **UI布局**
   - ✅ 响应式布局（移动/平板/桌面）
   - ✅ 导航栏和侧边栏
   - ✅ 响应式网格和列表

5. **API调用**
   - ✅ 所有API客户端完全支持
   - ✅ WebSocket连接
   - ✅ Token管理

---

## ⚠️ 需要适配的功能

### 1. 文件系统操作

**问题**: Web端不支持 `dart:io`，无法直接访问文件系统。

**影响文件**:
- `lib/services/download_service.dart`
- `lib/services/share_service.dart`
- `lib/services/gallery_service.dart`
- `lib/utils/video_cache_manager.dart`
- `lib/cache/media_cache_manager.dart`
- `lib/features/settings/screens/data_management_screen.dart` ✅ 已修复

**解决方案**:
- 使用条件导入 (`import ... if (dart.library.html) ...`)
- Web端使用浏览器API（如File API、Download API）
- 提供Web端特定的实现

### 2. 数据管理

**问题**: Web端无法计算缓存和数据库大小。

**状态**: ✅ 已修复
- 数据管理页面已适配Web端
- Web端显示"暂不支持计算"提示

### 3. 分享功能

**问题**: Web端分享API与移动端不同。

**解决方案**:
- 使用Web Share API (`navigator.share()`)
- 提供降级方案（复制链接）

### 4. 下载功能

**问题**: Web端下载方式不同。

**解决方案**:
- 使用 `<a>` 标签触发下载
- 或使用 `Blob` API创建下载

---

## 🔨 适配策略

### 策略1: 条件导入

```dart
// 移动端
import 'dart:io' if (dart.library.html) 'dart:html';

// 或使用kIsWeb检查
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web端实现
} else {
  // 移动端实现
}
```

### 策略2: 平台特定实现

创建Web端特定的实现文件：
- `lib/web/services/web_download_service.dart`
- `lib/web/services/web_share_service.dart`

### 策略3: 抽象接口

创建平台无关的接口，然后提供不同平台的实现。

---

## 📝 待适配文件清单

### 高优先级

1. **下载服务** (`lib/services/download_service.dart`)
   - [ ] 创建Web端下载实现
   - [ ] 使用浏览器下载API

2. **分享服务** (`lib/services/share_service.dart`)
   - [ ] 实现Web Share API
   - [ ] 提供降级方案


### 中优先级

4. **图库服务** (`lib/services/gallery_service.dart`)
   - [ ] 适配Web端文件访问
   - [ ] 使用IndexedDB存储

5. **媒体缓存管理** (`lib/cache/media_cache_manager.dart`)
   - [ ] 使用Web缓存API
   - [ ] 适配IndexedDB

6. **视频缓存管理** (`lib/utils/video_cache_manager.dart`)
   - [ ] Web端缓存策略
   - [ ] 使用Service Worker

### 低优先级

7. **其他UI组件**
   - [ ] 检查所有使用 `dart:io` 的组件
   - [ ] 提供Web端替代方案

---

## 🧪 测试清单

### Web端功能测试

- [ ] 登录/注册功能
- [ ] 对话列表和聊天
- [ ] 任务列表和详情
- [ ] 剧本生成和预览
- [ ] 图片生成和显示
- [ ] 视频生成和播放
- [ ] 设置页面
- [ ] 数据管理（清除缓存/数据库）
- [ ] 响应式布局（移动/平板/桌面）
- [ ] PWA功能（安装、离线）

### 浏览器兼容性

- [ ] Chrome/Edge (Chromium)
- [ ] Firefox
- [ ] Safari
- [ ] 移动端浏览器

---

## 🔗 相关文档

- [Web端开发状态](./WEB_IMPLEMENTATION_STATUS.md)
- [Web端工程实施方案](./Web端工程实施方案.md)
- [Flutter Web文档](https://docs.flutter.dev/platform-integration/web)

---

## 📝 更新日志

### 2026-01-12
- ✅ 修复数据管理页面Web适配
- ✅ 创建Web端主页面布局
- ✅ 创建平台适配说明文档
- ⏳ 待适配下载、分享等服务

---

**文档版本**: v1.0  
**最后更新**: 2026-01-12  
**维护者**: 开发团队
