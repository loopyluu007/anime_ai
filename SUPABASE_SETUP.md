# Supabase 集成指南

> **版本**: v2.0  
> **最后更新**: 2026-01-16  
> **注意**: 此文档已整合到 [完整部署指南](./DEPLOYMENT_GUIDE.md)，建议查看新文档

---

## 📌 重要提示

**此文档已整合到 [完整部署指南](./DEPLOYMENT_GUIDE.md)**，新文档包含：
- ✅ Supabase + Zeabur + Vercel 完整方案
- ✅ 更详细的配置步骤
- ✅ 完整的故障排查指南

**建议查看**: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) 中的 [Supabase 配置](#supabase-配置) 部分

---

# Supabase 集成指南（详细版，保留用于参考）

> **版本**: v1.0  
> **最后更新**: 2026-01-16

---

## 📋 概述

本指南说明如何将 AI漫导 项目集成 Supabase，使用 Supabase 的 PostgreSQL 数据库和 Storage 服务替代自建的基础设施。

---

## 🎯 为什么使用 Supabase？

### 优势

- ✅ **免费额度**：500MB 数据库 + 1GB 存储（适合开发和小型项目）
- ✅ **自动备份**：每日自动备份，可恢复到任意时间点
- ✅ **高可用**：99.9% 可用性保证
- ✅ **CDN 加速**：Storage 文件自动 CDN 加速
- ✅ **易于管理**：Web 界面管理数据库和存储
- ✅ **实时功能**：支持实时订阅（未来可扩展）
- ✅ **降低运维成本**：无需管理数据库和存储服务器

### 适用场景

- 云平台部署（Zeabur、Vercel、Railway 等）
- 快速上线和原型验证
- 小型到中型项目
- 需要降低运维成本

---

## 🚀 快速开始

### 1. 创建 Supabase 项目

1. 访问 [Supabase](https://supabase.com)
2. 注册/登录账户
3. 点击 "New Project"
4. 填写项目信息：
   - **Name**: director-ai（或自定义）
   - **Database Password**: 设置强密码（⚠️ 保存好）
   - **Region**: 选择离你最近的区域
5. 点击 "Create new project"
6. 等待项目初始化（约 2 分钟）

### 2. 获取数据库连接字符串

1. 进入项目 Dashboard
2. 点击左侧菜单 "Settings" → "Database"
3. 找到 "Connection string" 部分
4. 选择 "URI" 标签
5. 复制连接字符串，格式如下：
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
   ```
6. 将 `[YOUR-PASSWORD]` 替换为你创建项目时设置的密码

### 3. 创建 Storage Bucket

1. 进入项目 Dashboard
2. 点击左侧菜单 "Storage"
3. 点击 "New bucket"
4. 填写信息：
   - **Name**: `directorai-media`
   - **Public bucket**: 
     - ✅ 如果图片/视频需要公开访问，选择 Public
     - ❌ 如果需要认证访问，选择 Private
5. 点击 "Create bucket"

### 4. 获取 API 密钥

1. 进入项目 Dashboard
2. 点击左侧菜单 "Settings" → "API"
3. 复制以下信息：
   - **Project URL**: `https://[PROJECT-REF].supabase.co`
   - **anon key**: 用于客户端访问（前端使用）
   - **service_role key**: 用于服务端访问（⚠️ 保密，仅后端使用）

---

## 🔧 配置项目

### 1. 配置环境变量

在 `.env` 文件中添加 Supabase 配置：

```env
# Supabase 数据库连接
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Supabase Storage 配置（Media Service 使用）
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_KEY=[service_role key]
SUPABASE_BUCKET=directorai-media

# Redis（如果使用）
REDIS_URL=redis://localhost:6379/0

# 其他配置保持不变
SECRET_KEY=your-secret-key
GLM_API_KEY=your-glm-api-key
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key
```

### 2. 运行数据库迁移

#### 方式 1：使用 Supabase SQL Editor（推荐）

1. 进入 Supabase Dashboard
2. 点击左侧菜单 "SQL Editor"
3. 点击 "New query"
4. 打开 `backend/infrastructure/database/migrations/001_initial.sql`
5. 复制 SQL 内容到编辑器
6. 点击 "Run" 执行

#### 方式 2：使用 psql 命令行

```bash
# 安装 psql（如果未安装）
# macOS: brew install postgresql
# Ubuntu: sudo apt-get install postgresql-client

# 执行迁移
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -f backend/infrastructure/database/migrations/001_initial.sql
```

### 3. 配置 Storage 权限

在 Supabase Dashboard → Storage → Policies 中配置访问策略：

#### Public Bucket（公开访问）

```sql
-- 允许所有人读取
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'directorai-media');

-- 允许服务端写入（通过 service_role key）
-- 这个在代码中通过 Supabase 客户端处理
```

#### Private Bucket（需要认证）

```sql
-- 允许认证用户读取
CREATE POLICY "Authenticated users can read" ON storage.objects
FOR SELECT USING (
  bucket_id = 'directorai-media' 
  AND auth.role() = 'authenticated'
);

-- 允许服务端写入
-- 这个在代码中通过 service_role key 处理
```

---

## 📝 代码集成

### Media Service 集成 Supabase Storage

如果 Media Service 需要支持 Supabase Storage，需要安装 Supabase Python 客户端：

```bash
pip install supabase
```

然后在 Media Service 中添加 Supabase Storage 支持（可选，如果继续使用 MinIO 则不需要）。

---

## 🔍 验证配置

### 1. 测试数据库连接

```bash
# 使用 psql 测试连接
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 如果连接成功，执行：
\dt  # 查看所有表
\q   # 退出
```

### 2. 测试 Storage 访问

在 Supabase Dashboard → Storage → `directorai-media` 中：
- 尝试上传一个测试文件
- 检查文件是否可以访问

### 3. 测试应用连接

启动应用后，检查日志确认：
- ✅ 数据库连接成功
- ✅ Storage 配置正确（如果使用）

---

## 💡 最佳实践

### 1. 安全配置

- ⚠️ **保护 service_role key**：仅在服务端使用，不要暴露给客户端
- ✅ **使用环境变量**：不要硬编码密钥
- ✅ **定期轮换密码**：定期更新数据库密码和 API 密钥
- ✅ **配置 RLS**：如果使用 Private bucket，配置 Row Level Security

### 2. 性能优化

- ✅ **使用连接池**：Supabase 自动管理连接池
- ✅ **启用 CDN**：Storage 文件自动 CDN 加速
- ✅ **监控使用量**：在 Dashboard 中监控数据库和存储使用情况

### 3. 备份和恢复

- ✅ **自动备份**：Supabase 每日自动备份
- ✅ **时间点恢复**：可以在 Dashboard 中恢复到任意时间点
- ✅ **导出数据**：定期导出重要数据作为额外备份

---

## 🐛 常见问题

### 1. 数据库连接失败

**问题**: `sqlalchemy.exc.OperationalError: could not connect to server`

**解决**:
- 检查连接字符串格式是否正确
- 确认密码是否正确（注意 URL 编码特殊字符）
- 检查网络连接
- 确认 Supabase 项目状态正常

### 2. Storage 上传失败

**问题**: 文件上传到 Supabase Storage 失败

**解决**:
- 检查 `SUPABASE_KEY` 是否正确（使用 service_role key）
- 确认 Bucket 名称正确
- 检查 Storage 权限策略
- 查看 Supabase Dashboard 中的错误日志

### 3. 数据库迁移失败

**问题**: SQL 迁移脚本执行失败

**解决**:
- 检查 SQL 语法是否正确
- 确认表是否已存在（可能需要先删除）
- 查看 Supabase SQL Editor 中的错误信息
- 分步执行迁移（如果脚本很大）

---

## 📊 Supabase 免费计划限制

- **数据库**: 500MB
- **存储**: 1GB
- **带宽**: 2GB/月
- **API 请求**: 50,000/月

如果超出限制，需要升级到付费计划。

---

## 🔗 相关资源

- [Supabase 官方文档](https://supabase.com/docs)
- [Supabase Python 客户端](https://github.com/supabase/supabase-py)
- [Supabase Storage 文档](https://supabase.com/docs/guides/storage)
- [PostgreSQL 连接字符串格式](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)

---

**文档版本**: v1.0  
**最后更新**: 2026-01-16  
**维护者**: 开发团队
