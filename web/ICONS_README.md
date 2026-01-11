# PWA 图标资源说明

## 📋 需要的图标文件

为了完整支持 PWA（Progressive Web App），需要在 `web/icons/` 目录下创建以下图标文件：

### 必需图标

1. **icon-192.png** (192x192 像素)
   - 用途：PWA 图标（小尺寸）
   - 格式：PNG
   - 位置：`web/icons/icon-192.png`

2. **icon-512.png** (512x512 像素)
   - 用途：PWA 图标（大尺寸）
   - 格式：PNG
   - 位置：`web/icons/icon-512.png`

### 可选图标

3. **favicon.png** (32x32 或 64x64 像素)
   - 用途：浏览器标签页图标
   - 格式：PNG 或 ICO
   - 位置：`web/favicon.png`

## 🎨 图标设计建议

- **主题色**：使用 #8B5CF6（紫色）作为主色调
- **背景**：可以使用纯色背景或透明背景
- **内容**：建议包含应用 Logo 或代表性图标
- **风格**：简洁、现代、易于识别

## 📝 创建步骤

### 方法一：使用在线工具

1. 访问 [PWA Asset Generator](https://github.com/onderceylan/pwa-asset-generator)
2. 上传你的应用图标（建议 1024x1024 或更大）
3. 生成所需尺寸的图标
4. 下载并放置到对应目录

### 方法二：手动创建

1. 使用设计工具（如 Figma、Photoshop、GIMP）创建图标
2. 导出为所需尺寸的 PNG 文件
3. 确保图标清晰、无锯齿
4. 放置到对应目录

### 方法三：使用 Flutter 工具

```bash
# 如果你有 Flutter 应用的图标资源
flutter pub run flutter_launcher_icons:main
```

## ✅ 验证

创建图标后，可以通过以下方式验证：

1. **检查文件是否存在**：
   ```bash
   ls web/icons/icon-192.png
   ls web/icons/icon-512.png
   ls web/favicon.png
   ```

2. **检查 manifest.json**：
   确保 `web/manifest.json` 中正确引用了图标路径

3. **测试 PWA**：
   - 在浏览器中打开应用
   - 检查是否显示正确的图标
   - 尝试"添加到主屏幕"功能

## 📚 相关文档

- [Web App Manifest](https://developer.mozilla.org/en-US/docs/Web/Manifest)
- [PWA 图标指南](https://web.dev/add-manifest/#icons)
- [Flutter Web 部署](https://docs.flutter.dev/deployment/web)

## ⚠️ 注意事项

- 图标文件大小应尽量小（建议 < 100KB）
- 确保图标在不同背景下都清晰可见
- 测试在不同设备上的显示效果
- 定期更新图标以保持新鲜感

---

**提示**：在开发阶段，可以使用占位图标。但在生产环境部署前，请务必创建专业的应用图标。
