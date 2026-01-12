# Vercel 部署问题解决方案

## ❌ 常见错误：Flutter 命令未找到

### 错误信息
```
sh: line 1: flutter: command not found
Error: Command "flutter build web --release" exited with 127
```

### 原因
Vercel 默认不支持 Flutter，需要在构建时安装 Flutter SDK。

### 解决方案

#### 方案一：使用构建脚本（推荐）

1. **在 Vercel Dashboard 中配置项目设置**：

   - **Framework Preset**: 选择 "Other"
   - **Root Directory**: 留空
   - **Install Command**: 
     ```bash
     chmod +x scripts/vercel_build.sh && scripts/vercel_build.sh
     ```
   - **Build Command**: 
     ```bash
     echo "Build completed in install step"
     ```
     或者留空
   - **Output Directory**: `build/web`

2. **重新部署**

#### 方案二：使用单行命令

如果脚本不工作，使用单行命令：

- **Install Command**: 
  ```bash
  if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && export PATH="$PATH:$(pwd)/flutter/bin" && flutter config --enable-web && flutter pub get
  ```

- **Build Command**: 
  ```bash
  export PATH="$PATH:$(pwd)/flutter/bin" && flutter build web --release
  ```

- **Output Directory**: `build/web`

#### 方案三：使用 GitHub Actions（推荐用于生产环境）

如果 Vercel 构建一直失败，可以考虑使用 GitHub Actions 构建，然后将构建产物部署到 Vercel。

1. **创建 GitHub Actions 工作流**：

创建 `.github/workflows/build_flutter_web.yml`：

```yaml
name: Build Flutter Web

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build web
        run: flutter build web --release
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: build/web
```

2. **在本地构建后部署**：
   - 在本地运行 `flutter build web --release`
   - 将 `build/web` 目录推送到一个分支
   - 在 Vercel 中从该分支部署

### ⚠️ 注意事项

1. **构建时间**: 首次部署需要 5-10 分钟（下载 Flutter SDK）
2. **构建限制**: Vercel 免费计划有构建时间限制（通常足够，但如果超时考虑升级）
3. **缓存**: Vercel 会缓存 Flutter SDK，后续部署会更快

### 🔄 如果构建仍然失败

1. **检查构建日志**: 查看详细的错误信息
2. **检查网络**: 确保 Vercel 可以访问 GitHub（下载 Flutter SDK）
3. **尝试方案三**: 使用 GitHub Actions 构建
4. **考虑其他平台**: 
   - **Netlify**: 对 Flutter 支持更好（有 Flutter 构建插件）
   - **Firebase Hosting**: 支持 Flutter Web
   - **GitHub Pages**: 使用 GitHub Actions 构建后部署

---

**文档版本**: v1.0  
**最后更新**: 2026-01-XX
