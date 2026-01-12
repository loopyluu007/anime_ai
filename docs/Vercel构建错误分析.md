# Vercel 构建错误分析

## ❌ 错误：`chmod +x scripts/vercel_build.sh && scripts/vercel_build.sh` 退出代码 1

### 🔍 根本原因

**`.vercelignore` 文件排除了 `scripts/` 目录！**

`.vercelignore` 文件中有：
```
scripts/
```

这意味着 Vercel 在构建时**不会包含 scripts 目录**，所以：
- `scripts/vercel_build.sh` 文件在 Vercel 构建环境中**不存在**
- `chmod +x scripts/vercel_build.sh` 命令失败（文件不存在）
- 脚本执行失败，退出代码 1

### 其他可能的原因

1. **脚本执行失败**
   - `set -e` 导致任何命令失败都会立即退出
   - 可能是某个步骤失败（git clone、flutter 命令等）

2. **路径问题**
   - 脚本中的路径可能不正确

3. **网络问题**
   - git clone Flutter SDK 可能超时或失败
   - Vercel 可能无法访问 GitHub

4. **环境变量问题**
   - PATH 环境变量在命令之间可能不会保留

### 解决方案

#### 方案一：不使用脚本，使用单行命令（推荐）

在 Vercel 项目设置中直接使用命令，不使用脚本：

**Install Command**:
```bash
if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && export PATH="$PATH:$(pwd)/flutter/bin" && flutter config --enable-web && flutter pub get
```

**Build Command**:
```bash
export PATH="$PATH:$(pwd)/flutter/bin" && flutter build web --release
```

**Output Directory**: `build/web`

#### 方案二：修改脚本，移除 `set -e` 并添加错误处理

如果必须使用脚本，需要：
1. 移除 `set -e` 或添加错误处理
2. 确保所有命令都能正确执行
3. 添加调试输出

但推荐使用方案一（单行命令），因为更简单、更可靠。

### 为什么脚本可能失败？

1. **Vercel 的环境限制**：
   - Install Command 和 Build Command 的执行环境可能不完全相同
   - 环境变量（如 PATH）可能不会在命令之间保留

2. **脚本中的错误处理**：
   - `set -e` 会在任何命令失败时立即退出
   - 如果 git clone 失败、flutter 命令失败等，脚本会立即退出

3. **网络或权限问题**：
   - git clone 可能失败
   - 文件权限问题

### 推荐的最终配置

**Vercel 项目设置**：

- **Framework Preset**: Other
- **Root Directory**: （留空）
- **Install Command**: 
  ```bash
  if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && export PATH="$PATH:$(pwd)/flutter/bin" && flutter config --enable-web && flutter pub get
  ```
- **Build Command**: 
  ```bash
  export PATH="$PATH:$(pwd)/flutter/bin" && flutter build web --release
  ```
- **Output Directory**: `build/web`

这样配置更可靠，因为：
- 不依赖脚本文件
- 直接在 Install Command 中设置 PATH
- Build Command 中再次设置 PATH（确保可用）
- 每个命令都是独立的，更容易调试

---

**文档版本**: v1.0  
**最后更新**: 2026-01-XX
