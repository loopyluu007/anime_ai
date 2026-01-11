# PWA 图标创建指南

## 📋 图标需求

Web端需要以下图标文件：

1. **favicon.png** - 网站图标 (32x32 或 64x64)
   - 位置: `web/favicon.png`
   - 用途: 浏览器标签页图标

2. **icon-192.png** - PWA图标 (192x192)
   - 位置: `web/icons/icon-192.png`
   - 用途: PWA应用图标（小尺寸）

3. **icon-512.png** - PWA图标 (512x512)
   - 位置: `web/icons/icon-512.png`
   - 用途: PWA应用图标（大尺寸）

## 🎨 设计规范

### 图标设计建议

- **主题**: AI漫导 - AI智能体驱动的短剧制作平台
- **风格**: 现代、简洁、科技感
- **颜色**: 主色调 #8B5CF6 (紫色)
- **元素**: 可以包含电影胶片、AI、创作等元素

### 设计工具

可以使用以下工具创建图标：

1. **在线工具**:
   - [Favicon.io](https://favicon.io/) - 快速生成favicon
   - [RealFaviconGenerator](https://realfavicongenerator.net/) - 完整的favicon生成
   - [PWA Asset Generator](https://github.com/onderceylan/pwa-asset-generator) - PWA图标生成

2. **设计软件**:
   - Figma
   - Adobe Illustrator
   - Sketch

3. **AI生成**:
   - 可以使用AI图像生成工具（如Midjourney、DALL-E）生成图标

## 📐 技术规格

### favicon.png
- **尺寸**: 32x32 或 64x64 像素
- **格式**: PNG（支持透明背景）
- **文件大小**: < 10KB

### icon-192.png
- **尺寸**: 192x192 像素
- **格式**: PNG（支持透明背景）
- **文件大小**: < 50KB
- **用途**: 移动设备主屏幕图标

### icon-512.png
- **尺寸**: 512x512 像素
- **格式**: PNG（支持透明背景）
- **文件大小**: < 200KB
- **用途**: 桌面设备主屏幕图标、启动画面

## 🔧 创建步骤

### 方法1: 使用在线工具

1. 访问 [Favicon.io](https://favicon.io/)
2. 上传你的设计图（建议1024x1024）
3. 生成所有尺寸的图标
4. 下载并放置到对应目录

### 方法2: 使用设计软件

1. 在Figma/Illustrator中创建1024x1024的设计
2. 导出为PNG格式
3. 使用图像编辑软件（如Photoshop）调整尺寸：
   - favicon.png: 64x64
   - icon-192.png: 192x192
   - icon-512.png: 512x512
4. 优化文件大小（使用TinyPNG等工具）
5. 放置到对应目录

### 方法3: 使用命令行工具

```bash
# 安装PWA Asset Generator
npm install -g pwa-asset-generator

# 从源图像生成所有图标
pwa-asset-generator source-image.png web/icons/ \
  --icon-only \
  --favicon \
  --opaque false \
  --padding "10%"
```

## ✅ 验证

创建图标后，请验证：

1. **文件存在性**:
   ```bash
   ls web/favicon.png
   ls web/icons/icon-192.png
   ls web/icons/icon-512.png
   ```

2. **文件大小**: 检查文件大小是否合理

3. **浏览器测试**:
   - 运行 `flutter run -d chrome`
   - 检查浏览器标签页图标
   - 检查PWA安装提示

4. **PWA测试**:
   - 在Chrome中打开应用
   - 点击地址栏的"安装"按钮
   - 检查主屏幕图标是否正确显示

## 📝 临时占位符

在正式图标创建之前，可以使用以下方法创建占位符：

### 使用Flutter创建占位符

```dart
// 创建一个简单的占位符图标生成脚本
// 可以创建一个简单的紫色圆形图标
```

### 使用在线占位符

- 访问 [Placeholder.com](https://via.placeholder.com/)
- 生成占位符图片：
  - `https://via.placeholder.com/64/8B5CF6/FFFFFF?text=AI`
  - `https://via.placeholder.com/192/8B5CF6/FFFFFF?text=AI`
  - `https://via.placeholder.com/512/8B5CF6/FFFFFF?text=AI`

## 🔗 相关文档

- [Web端开发状态](../docs/02-implementation/WEB_IMPLEMENTATION_STATUS.md)
- [PWA Manifest配置](../manifest.json)
- [HTML入口文件](../index.html)

---

**注意**: 图标是PWA的重要组成部分，建议使用专业设计的图标以获得最佳用户体验。
