# Vercel 构建错误原因分析

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

### ✅ 解决方案

**使用单行命令，不使用脚本**

在 Vercel Dashboard 中配置：

- **Install Command**: 
  ```bash
  if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && export PATH="$PATH:$(pwd)/flutter/bin" && flutter config --enable-web && flutter pub get
  ```

- **Build Command**: 
  ```bash
  export PATH="$PATH:$(pwd)/flutter/bin" && flutter build web --release
  ```

- **Output Directory**: `build/web`

### 为什么使用单行命令而不是脚本？

1. ✅ **`.vercelignore` 排除了 scripts 目录** - 脚本文件不存在
2. ✅ **不依赖文件** - 单行命令直接在命令中执行
3. ✅ **更容易调试** - 错误信息更清晰
4. ✅ **更可靠** - 不依赖文件系统权限和路径

### 如果要从 `.vercelignore` 中排除 scripts 目录

如果你真的想使用脚本（不推荐），需要：

1. **修改 `.vercelignore`**，移除 `scripts/` 或改为：
   ```
   # 排除其他脚本，但保留 Vercel 构建脚本
   scripts/test_*.sh
   scripts/test_*.bat
   scripts/generate_*.py
   ```

2. **但这样会包含所有脚本文件**，增加部署大小

**推荐**：使用单行命令，更简单、更可靠。

---

**文档版本**: v1.0  
**最后更新**: 2026-01-XX
