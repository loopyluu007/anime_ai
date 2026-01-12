# 🚀 AI漫导 完整部署指南

> **架构方案**: Supabase (数据库) + Zeabur (后端微服务) + Vercel (前端)  
> **版本**: v2.0  
> **最后更新**: 2026-01-16

---

## 📋 目录

1. [架构概览](#架构概览)
2. [前置准备](#前置准备)
3. [Supabase 配置](#supabase-配置)
4. [Zeabur 后端部署](#zeabur-后端部署)
5. [Vercel 前端部署](#vercel-前端部署)
6. [环境变量配置](#环境变量配置)
7. [验证和测试](#验证和测试)
8. [故障排查](#故障排查)

---

## 🏗️ 架构概览

### 技术栈

| 组件 | 平台 | 用途 |
|------|------|------|
| **数据库** | Supabase | PostgreSQL 数据库 + Storage 对象存储 |
| **后端服务** | Zeabur | 4个微服务（API Gateway、Agent、Media、Data） |
| **前端** | Vercel | Flutter Web 应用 |

### 架构图

```
┌─────────────────────────────────────────────────────────┐
│                     用户访问                              │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   Vercel (前端)       │
         │   Flutter Web App     │
         └───────────┬───────────┘
                     │
                     │ HTTPS
                     ▼
         ┌───────────────────────┐
         │  Zeabur: API Gateway  │
         │   (端口 8000)          │
         └───┬───────┬───────┬───┘
             │       │       │
    ┌────────┘       │       └────────┐
    │                │                │
    ▼                ▼                ▼
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Agent   │    │ Media   │    │ Data    │
│ Service │    │ Service │    │ Service │
│ :8001   │    │ :8002   │    │ :8003   │
└────┬────┘    └────┬────┘    └────┬────┘
     │             │              │
     └─────────────┴──────────────┘
                   │
                   ▼
         ┌───────────────────────┐
         │   Supabase            │
         │   - PostgreSQL        │
         │   - Storage           │
         └───────────────────────┘
```

### 优势

- ✅ **Supabase**: 免费额度充足，自动备份，CDN 加速
- ✅ **Zeabur**: 简单易用，自动扩缩容，支持 Docker
- ✅ **Vercel**: 全球 CDN，自动 HTTPS，零配置部署
- ✅ **完全托管**: 无需管理服务器，降低运维成本

---

## 🔧 前置准备

### 1. 账户注册

- [ ] 注册 [Supabase](https://supabase.com) 账户
- [ ] 注册 [Zeabur](https://zeabur.com) 账户
- [ ] 注册 [Vercel](https://vercel.com) 账户
- [ ] 准备 GitHub 仓库（用于连接部署平台）

### 2. API 密钥准备

- [ ] GLM API Key（智谱 AI）
- [ ] Tuzi API Key（图子视频生成）
- [ ] Gemini API Key（Google 图片生成）

### 3. 项目准备

- [ ] 确保代码已推送到 GitHub
- [ ] 确认项目结构正确
- [ ] 准备环境变量列表

---

## 🗄️ Supabase 配置

### 1. 创建 Supabase 项目

1. 访问 [Supabase Dashboard](https://app.supabase.com)
2. 点击 "New Project"
3. 填写项目信息：
   - **Name**: `director-ai`（或自定义）
   - **Database Password**: 设置强密码（⚠️ 保存好）
   - **Region**: 选择离你最近的区域（推荐：`Southeast Asia (Singapore)`）
4. 点击 "Create new project"
5. 等待项目初始化（约 2 分钟）

### 2. 获取数据库连接字符串

1. 进入项目 Dashboard
2. 点击左侧菜单 "Settings" → "Database"
3. 找到 "Connection string" 部分
4. 选择 "URI" 标签
5. 复制连接字符串，格式：
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
   - **Public bucket**: ✅ 选择 Public（如果需要公开访问图片/视频）
5. 点击 "Create bucket"

### 4. 获取 API 密钥

1. 进入项目 Dashboard
2. 点击左侧菜单 "Settings" → "API"
3. 复制以下信息：
   - **Project URL**: `https://[PROJECT-REF].supabase.co`
   - **anon key**: 用于客户端访问（前端使用，可选）
   - **service_role key**: 用于服务端访问（⚠️ 保密，仅后端使用）

### 5. 运行数据库迁移

#### 方式 1：使用 Supabase SQL Editor（推荐）

1. 进入 Supabase Dashboard
2. 点击左侧菜单 "SQL Editor"
3. 点击 "New query"
4. 打开 `backend/infrastructure/database/migrations/001_initial.sql`
5. 复制 SQL 内容到编辑器
6. 点击 "Run" 执行

#### 方式 2：使用 psql 命令行

```bash
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
  -f backend/infrastructure/database/migrations/001_initial.sql
```

### 6. 配置 Storage 权限

在 Supabase Dashboard → Storage → Policies 中配置访问策略：

```sql
-- 允许公开读取（如果 Bucket 是 Public）
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'directorai-media');

-- 允许服务端写入（通过 service_role key 在代码中处理）
```

---

## 🐳 Zeabur 后端部署

### 部署架构

在 Zeabur 上需要部署 4 个独立的服务：

1. **API Gateway** - 统一入口，端口 8000
2. **Agent Service** - 业务服务，端口 8001
3. **Media Service** - 媒体服务，端口 8002
4. **Data Service** - 数据服务，端口 8003

### 部署步骤

#### 1. 连接 GitHub 仓库

1. 登录 [Zeabur Dashboard](https://dash.zeabur.com)
2. 点击 "New Project"
3. 选择 "Import from GitHub"
4. 选择你的仓库
5. 授权 Zeabur 访问仓库

#### 2. 部署 Agent Service

1. 在 Zeabur 项目中点击 "New Service"
2. 选择你的 GitHub 仓库
3. 配置服务：
   - **Service Name**: `agent-service`
   - **Dockerfile Path**: `backend/services/agent_service/Dockerfile.zeabur`
   - **Port**: `8001`
4. 配置环境变量（见下方 [环境变量配置](#环境变量配置)）
5. 点击 "Deploy"

#### 3. 部署 Media Service

1. 重复步骤 2，创建新服务
2. 配置：
   - **Service Name**: `media-service`
   - **Dockerfile Path**: `backend/services/media_service/Dockerfile.zeabur`
   - **Port**: `8002`
3. 配置环境变量（包含 Supabase Storage 配置）
4. 部署

#### 4. 部署 Data Service

1. 重复步骤 2，创建新服务
2. 配置：
   - **Service Name**: `data-service`
   - **Dockerfile Path**: `backend/services/data_service/Dockerfile.zeabur`
   - **Port**: `8003`
3. 配置环境变量
4. 部署

#### 5. 部署 API Gateway

1. 重复步骤 2，创建新服务
2. 配置：
   - **Service Name**: `api-gateway`
   - **Dockerfile Path**: `backend/api_gateway/Dockerfile.zeabur`
   - **Port**: `8000`
3. 配置环境变量（包含其他服务的 URL）
4. 部署

#### 6. 获取服务 URL

部署完成后，在 Zeabur Dashboard 中获取每个服务的 URL：
- `https://agent-service-[hash].zeabur.app`
- `https://media-service-[hash].zeabur.app`
- `https://data-service-[hash].zeabur.app`
- `https://api-gateway-[hash].zeabur.app`

### 服务间通信配置

在 API Gateway 的环境变量中配置其他服务的 URL：

```env
AGENT_SERVICE_URL=https://agent-service-[hash].zeabur.app
MEDIA_SERVICE_URL=https://media-service-[hash].zeabur.app
DATA_SERVICE_URL=https://data-service-[hash].zeabur.app
```

---

## ⚡ Vercel 前端部署

### 部署步骤

#### 1. 连接 GitHub 仓库

1. 登录 [Vercel Dashboard](https://vercel.com/dashboard)
2. 点击 "Add New..." → "Project"
3. 选择你的 GitHub 仓库
4. 授权 Vercel 访问仓库

#### 2. 配置项目

1. **Framework Preset**: 选择 "Flutter" 或 "Other"
2. **Root Directory**: 留空（项目根目录）
3. **Build Command**: 留空（Vercel 会自动检测）
4. **Output Directory**: `build/web`
5. **Install Command**: `flutter pub get`

#### 3. 配置环境变量

在 Vercel 项目设置中添加环境变量：

```env
API_BASE_URL=https://api-gateway-[hash].zeabur.app/api/v1
WS_URL=wss://api-gateway-[hash].zeabur.app/ws
```

#### 4. 部署

1. 点击 "Deploy"
2. 等待构建完成（约 3-5 分钟）
3. 获取部署 URL：`https://your-project.vercel.app`

### Vercel 配置说明

项目根目录已包含 `vercel.json` 配置文件，Vercel 会自动识别：

- ✅ Flutter Web 构建配置
- ✅ SPA 路由重写规则
- ✅ 安全头配置
- ✅ 静态资源缓存策略

---

## 🔐 环境变量配置

### Supabase 配置（所有后端服务）

```env
# Supabase PostgreSQL 数据库
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Supabase Storage 配置（Media Service 需要）
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_KEY=[service_role key]
SUPABASE_BUCKET=directorai-media
```

### 通用配置（所有后端服务）

```env
# Redis（可选，如果使用）
REDIS_URL=redis://redis-host:6379/0

# JWT 配置
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# API 密钥
GLM_API_KEY=your-glm-api-key
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key
```

### API Gateway 专用配置

```env
# 服务地址（部署后获取）
AGENT_SERVICE_URL=https://agent-service-[hash].zeabur.app
MEDIA_SERVICE_URL=https://media-service-[hash].zeabur.app
DATA_SERVICE_URL=https://data-service-[hash].zeabur.app

# CORS 配置
CORS_ORIGINS=https://your-project.vercel.app,https://www.your-domain.com

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

### Vercel 前端配置

```env
API_BASE_URL=https://api-gateway-[hash].zeabur.app/api/v1
WS_URL=wss://api-gateway-[hash].zeabur.app/ws
```

---

## ✅ 验证和测试

### 1. 验证 Supabase

```bash
# 测试数据库连接
psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# 查看表
\dt

# 退出
\q
```

### 2. 验证后端服务

```bash
# 测试 API Gateway
curl https://api-gateway-[hash].zeabur.app/health

# 测试 Agent Service
curl https://agent-service-[hash].zeabur.app/health

# 测试 Media Service
curl https://media-service-[hash].zeabur.app/health

# 测试 Data Service
curl https://data-service-[hash].zeabur.app/health
```

### 3. 验证前端

1. 访问 Vercel 部署 URL
2. 检查页面是否正常加载
3. 测试 API 连接（打开浏览器开发者工具）
4. 测试主要功能

### 4. 端到端测试

1. 在前端创建对话
2. 测试图片生成
3. 测试视频生成
4. 检查数据是否保存到 Supabase

---

## 🐛 故障排查

### 后端服务无法启动

**问题**: Zeabur 部署失败或服务无法启动

**解决**:
1. 检查 Dockerfile 路径是否正确
2. 查看 Zeabur 构建日志
3. 确认环境变量配置正确
4. 检查端口配置（Zeabur 会自动映射）

### 数据库连接失败

**问题**: `sqlalchemy.exc.OperationalError: could not connect to server`

**解决**:
1. 检查 `DATABASE_URL` 格式是否正确
2. 确认密码是否正确（注意 URL 编码特殊字符）
3. 检查 Supabase 项目状态
4. 确认网络连接正常

### 服务间通信失败

**问题**: API Gateway 无法连接到其他服务

**解决**:
1. 确认所有服务都已部署成功
2. 检查服务 URL 配置是否正确
3. 确认服务健康检查通过
4. 查看 Zeabur 服务日志

### 前端无法连接后端

**问题**: CORS 错误或 API 请求失败

**解决**:
1. 检查 `API_BASE_URL` 配置是否正确
2. 在 API Gateway 中配置 `CORS_ORIGINS`
3. 确认 API Gateway 正常运行
4. 检查浏览器控制台错误信息

### Storage 上传失败

**问题**: 文件上传到 Supabase Storage 失败

**解决**:
1. 检查 `SUPABASE_KEY` 是否正确（使用 service_role key）
2. 确认 Bucket 名称正确
3. 检查 Storage 权限策略
4. 查看 Supabase Dashboard 中的错误日志

---

## 📊 成本估算

### Supabase（免费计划）

- ✅ 500MB 数据库
- ✅ 1GB 存储
- ✅ 2GB/月 带宽
- ✅ 50,000 API 请求/月

**适合**: 开发和小型项目

### Zeabur

- ✅ 免费额度：$5/月
- 💰 超出后按使用量计费

### Vercel

- ✅ 免费计划：100GB 带宽/月
- ✅ 无限请求
- ✅ 自动 HTTPS

**总计**: 免费计划足够开发和小型项目使用

---

## 🔗 相关文档

- [Supabase 集成指南](./SUPABASE_SETUP.md) - Supabase 详细配置
- [Zeabur 部署指南](./ZEABUR_DEPLOYMENT.md) - Zeabur 详细说明
- [统一部署指南](./DEPLOYMENT.md) - 本地 Docker 部署
- [快速开始指南](./QUICKSTART.md) - 开发环境搭建

---

## 📝 部署检查清单

### 部署前

- [ ] 已注册所有平台账户
- [ ] 已准备所有 API 密钥
- [ ] 代码已推送到 GitHub
- [ ] 已创建 Supabase 项目
- [ ] 已运行数据库迁移

### 部署中

- [ ] 已部署 Agent Service
- [ ] 已部署 Media Service
- [ ] 已部署 Data Service
- [ ] 已部署 API Gateway
- [ ] 已配置服务间通信
- [ ] 已部署前端到 Vercel

### 部署后

- [ ] 所有服务健康检查通过
- [ ] 前端可以访问
- [ ] API 请求正常
- [ ] 数据库连接正常
- [ ] Storage 上传正常
- [ ] 端到端功能测试通过

---

**文档版本**: v2.0  
**最后更新**: 2026-01-16  
**维护者**: 开发团队
