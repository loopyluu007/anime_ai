# 🚀 AI漫导 完整部署指南

> **架构方案**: Supabase (数据库) + Zeabur (后端微服务) + Vercel (前端)  
> **版本**: v3.0  
> **最后更新**: 2026-01-XX

> 💡 **提示**: 本文档是统一的部署指南，包含所有部署信息（云平台部署、本地部署、AI自动部署等）。所有部署相关的内容都在这里。

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
4. 复制以下 SQL 内容到编辑器并执行：

```sql
-- 创建用户表
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    is_active BOOLEAN DEFAULT true,
    glm_api_key TEXT,
    tuzi_api_key TEXT,
    gemini_api_key TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建对话表
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    preview_text TEXT,
    message_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT false,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建消息表
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'text' CHECK (type IN ('text', 'image', 'video', 'screenplay')),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建任务表
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('screenplay', 'image', 'video')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    params JSONB,
    result JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 创建剧本表
CREATE TABLE screenplays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'confirmed', 'generating', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建场景表
CREATE TABLE scenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screenplay_id UUID NOT NULL REFERENCES screenplays(id) ON DELETE CASCADE,
    scene_id INTEGER NOT NULL,
    narration TEXT NOT NULL,
    image_prompt TEXT NOT NULL,
    video_prompt TEXT NOT NULL,
    character_description TEXT,
    image_url TEXT,
    video_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'generating', 'completed', 'failed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(screenplay_id, scene_id)
);

-- 创建角色设定表
CREATE TABLE character_sheets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    screenplay_id UUID NOT NULL REFERENCES screenplays(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    combined_view_url TEXT,
    front_view_url TEXT,
    side_view_url TEXT,
    back_view_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建媒体文件表
CREATE TABLE media_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('image', 'video')),
    original_filename VARCHAR(255),
    storage_path TEXT NOT NULL,
    url TEXT NOT NULL,
    mime_type VARCHAR(100),
    size BIGINT,
    width INTEGER,
    height INTEGER,
    duration INTEGER,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建任务日志表
CREATE TABLE task_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    level VARCHAR(20) NOT NULL CHECK (level IN ('info', 'warning', 'error')),
    message TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_user_updated ON conversations(user_id, updated_at DESC);
CREATE INDEX idx_conversations_user_pinned ON conversations(user_id, is_pinned DESC, updated_at DESC);
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_type ON messages(type);
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_conversation_id ON tasks(conversation_id);
CREATE INDEX idx_tasks_type ON tasks(type);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_screenplays_task_id ON screenplays(task_id);
CREATE INDEX idx_screenplays_user_id ON screenplays(user_id);
CREATE INDEX idx_screenplays_status ON screenplays(status);
CREATE INDEX idx_scenes_screenplay_id ON scenes(screenplay_id);
CREATE INDEX idx_scenes_status ON scenes(status);
CREATE INDEX idx_character_sheets_screenplay_id ON character_sheets(screenplay_id);
CREATE INDEX idx_media_files_user_id ON media_files(user_id);
CREATE INDEX idx_media_files_type ON media_files(type);
CREATE INDEX idx_media_files_created ON media_files(created_at DESC);
CREATE INDEX idx_task_logs_task_id ON task_logs(task_id);
CREATE INDEX idx_task_logs_level ON task_logs(level);
CREATE INDEX idx_task_logs_created ON task_logs(created_at DESC);
```

5. 点击 "Run" 执行

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
6. ⏱️ 等待构建和部署完成（约 3-5 分钟，首次部署可能需要更长时间）
7. 记录服务 URL: `https://agent-service-[hash].zeabur.app`

#### 3. 部署 Media Service

1. 在 Zeabur 项目中点击 "New Service"
2. 选择你的 GitHub 仓库
3. 配置服务：
   - **Service Name**: `media-service`
   - **Dockerfile Path**: `backend/services/media_service/Dockerfile.zeabur`
   - **Port**: `8002`
4. 配置环境变量（包含 Supabase Storage 配置，见下方 [环境变量配置](#环境变量配置)）
5. 点击 "Deploy"
6. ⏱️ 等待构建和部署完成（约 3-5 分钟）
7. 记录服务 URL: `https://media-service-[hash].zeabur.app`

#### 4. 部署 Data Service

1. 在 Zeabur 项目中点击 "New Service"
2. 选择你的 GitHub 仓库
3. 配置服务：
   - **Service Name**: `data-service`
   - **Dockerfile Path**: `backend/services/data_service/Dockerfile.zeabur`
   - **Port**: `8003`
4. 配置环境变量（见下方 [环境变量配置](#环境变量配置)）
5. 点击 "Deploy"
6. ⏱️ 等待构建和部署完成（约 3-5 分钟）
7. 记录服务 URL: `https://data-service-[hash].zeabur.app`

#### 5. 部署 API Gateway（最后部署）

⚠️ **重要**: 必须先部署 Agent、Media、Data 服务，获取它们的 URL 后才能部署 API Gateway。

1. 在 Zeabur 项目中点击 "New Service"
2. 选择你的 GitHub 仓库
3. 配置服务：
   - **Service Name**: `api-gateway`
   - **Dockerfile Path**: `backend/api_gateway/Dockerfile.zeabur`
   - **Port**: `8000`
4. 配置环境变量（包含其他服务的 URL，见下方 [环境变量配置](#环境变量配置)）
5. 点击 "Deploy"
6. ⏱️ 等待构建和部署完成（约 3-5 分钟）
7. 记录服务 URL: `https://api-gateway-[hash].zeabur.app`（这是前端需要配置的 API 地址）

> 💡 **提示**: 项目已优化健康检查配置（60秒启动期），服务有充足的启动时间。Zeabur 会自动处理健康检查，无需手动配置。

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

⚠️ **重要**: Vercel 默认不支持 Flutter，需要手动配置构建环境。

**⚠️ 重要发现**：`.vercelignore` 文件中排除了 `scripts/` 目录，导致脚本在 Vercel 环境中不存在！

**推荐方案：使用单行命令（不使用脚本）**

不使用脚本的原因是：
1. `.vercelignore` 排除了 `scripts/` 目录
2. 脚本文件在 Vercel 构建环境中不存在
3. 单行命令更简单、更可靠

**配置步骤**：

1. **Framework Preset**: 选择 "Other"
2. **Root Directory**: 留空
3. **Install Command**: 
   ```bash
   if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && export PATH="$PATH:$(pwd)/flutter/bin" && flutter config --enable-web && flutter pub get
   ```
4. **Build Command**: 
   ```bash
   export PATH="$PATH:$(pwd)/flutter/bin" && flutter build web --release
   ```
5. **Output Directory**: `build/web`

**⚠️ 注意**:
- 首次部署可能需要 5-10 分钟（需要下载 Flutter SDK，约 1GB）
- 确保有足够的构建时间（Vercel 免费计划有构建时间限制）
- 如果构建超时，考虑使用 GitHub Actions 构建，然后部署构建产物

#### 3. 配置环境变量

在 Vercel 项目设置中添加环境变量：

```env
API_BASE_URL=https://api-gateway-[hash].zeabur.app/api/v1
WS_URL=wss://api-gateway-[hash].zeabur.app/ws
```

#### 4. 部署

1. 点击 "Deploy"
2. 等待构建完成（首次部署可能需要 5-10 分钟，因为需要安装 Flutter SDK）
3. 获取部署 URL：`https://your-project.vercel.app`

### Vercel 配置说明

项目根目录已包含 `vercel.json` 配置文件，Vercel 会自动识别：

- ✅ SPA 路由重写规则（所有路由返回 index.html，支持 Flutter Web 路由）
- ✅ 安全头配置
- ✅ 静态资源缓存策略

**重要**: 如果部署后遇到 404 错误，请检查：
1. `vercel.json` 文件是否存在且配置正确
2. Vercel 项目设置中的 "Output Directory" 是否设置为 `build/web`
3. "Build Command" 是否设置为 `flutter build web --release`

---

## 🔐 环境变量配置

### 所有服务通用环境变量

| 变量名 | 必需 | 说明 | 示例值 |
|--------|------|------|--------|
| `DATABASE_URL` | ✅ | Supabase PostgreSQL 连接字符串 | `postgresql://postgres:password@db.xxx.supabase.co:5432/postgres` |
| `SECRET_KEY` | ✅ | JWT 密钥（所有服务必须相同） | `your-strong-secret-key-here` |
| `ALGORITHM` | ✅ | JWT 算法 | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | ✅ | Token 过期时间（分钟） | `60` |

### Agent Service 环境变量

**通用变量**（见上表）+ 以下专用变量：

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `GLM_API_KEY` | ✅ | 智谱 AI API 密钥 |
| `PORT` | ✅ | 服务端口 | `8001` |

**完整配置示例**:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
GLM_API_KEY=your-glm-api-key
PORT=8001
```

### Media Service 环境变量

**通用变量**（见上表）+ 以下专用变量：

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `SUPABASE_URL` | ✅ | Supabase 项目 URL |
| `SUPABASE_KEY` | ✅ | Supabase service_role 密钥 |
| `SUPABASE_BUCKET` | ✅ | Storage Bucket 名称 | `directorai-media` |
| `TUZI_API_KEY` | ✅ | 图子视频生成 API 密钥 |
| `GEMINI_API_KEY` | ✅ | Google Gemini API 密钥 |
| `PORT` | ✅ | 服务端口 | `8002` |

**完整配置示例**:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_KEY=[service_role key]
SUPABASE_BUCKET=directorai-media
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key
PORT=8002
```

### Data Service 环境变量

**通用变量**（见上表）+ 以下专用变量：

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `PORT` | ✅ | 服务端口 | `8003` |

**完整配置示例**:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
PORT=8003
```

### API Gateway 环境变量

**通用变量**（见上表）+ 以下专用变量：

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `AGENT_SERVICE_URL` | ✅ | Agent Service 的完整 URL |
| `MEDIA_SERVICE_URL` | ✅ | Media Service 的完整 URL |
| `DATA_SERVICE_URL` | ✅ | Data Service 的完整 URL |
| `CORS_ORIGINS` | ✅ | 允许的前端域名（逗号分隔） |
| `RATE_LIMIT_ENABLED` | ⚠️ | 是否启用限流 | `true` |
| `RATE_LIMIT_REQUESTS` | ⚠️ | 限流请求数 | `100` |
| `RATE_LIMIT_WINDOW` | ⚠️ | 限流时间窗口（秒） | `60` |
| `PORT` | ✅ | 服务端口 | `8000` |

**完整配置示例**:
```env
DATABASE_URL=postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
AGENT_SERVICE_URL=https://agent-service-[hash].zeabur.app
MEDIA_SERVICE_URL=https://media-service-[hash].zeabur.app
DATA_SERVICE_URL=https://data-service-[hash].zeabur.app
CORS_ORIGINS=https://your-project.vercel.app,https://www.your-domain.com
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
PORT=8000
```

⚠️ **重要**: 
- `SECRET_KEY` 在所有后端服务中必须完全相同
- `AGENT_SERVICE_URL`, `MEDIA_SERVICE_URL`, `DATA_SERVICE_URL` 需要使用部署后获取的实际 URL
- `CORS_ORIGINS` 需要配置前端域名，多个域名用逗号分隔

### Vercel 前端环境变量

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `API_BASE_URL` | ✅ | API Gateway 的完整 URL + `/api/v1` |
| `WS_URL` | ✅ | WebSocket URL（使用 `wss://`） |

**完整配置示例**:
```env
API_BASE_URL=https://api-gateway-[hash].zeabur.app/api/v1
WS_URL=wss://api-gateway-[hash].zeabur.app/ws
```

### Dockerfile 路径参考

| 服务 | Dockerfile 路径 |
|------|----------------|
| API Gateway | `backend/api_gateway/Dockerfile.zeabur` |
| Agent Service | `backend/services/agent_service/Dockerfile.zeabur` |
| Media Service | `backend/services/media_service/Dockerfile.zeabur` |
| Data Service | `backend/services/data_service/Dockerfile.zeabur` |

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
5. 注意：项目已优化健康检查配置，服务有60秒启动期，首次部署可能需要更长时间

### 服务启动时间过长

**问题**: 服务部署后启动时间超过预期

**说明**: 
- 项目已优化健康检查配置（启动期60秒，重试5次）
- 首次部署需要初始化数据库、安装依赖等，可能需要更长时间
- Zeabur 会自动处理健康检查，无需手动配置

**解决**:
1. 查看 Zeabur 构建日志，确认构建是否成功
2. 查看服务运行日志，检查是否有错误
3. 确认环境变量配置正确（特别是数据库连接）
4. 检查资源限制，确保服务有足够资源

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

### Vercel 构建失败：脚本命令退出代码 1

**问题**: `Error: Command "chmod +x scripts/vercel_build.sh && scripts/vercel_build.sh" exited with 1`

**根本原因**: **`.vercelignore` 文件排除了 `scripts/` 目录**，脚本文件在 Vercel 构建环境中不存在！

**解决方案**:

#### 推荐方案：使用单行命令（不使用脚本）

⚠️ **原因**：`.vercelignore` 文件排除了 `scripts/` 目录，脚本文件在 Vercel 环境中不存在。

**在 Vercel Dashboard 中配置**:
1. **Framework Preset**: "Other"
2. **Root Directory**: 留空
3. **Install Command**: 
   ```bash
   if [ -d "flutter" ]; then cd flutter && git pull && cd ..; else git clone https://github.com/flutter/flutter.git -b stable --depth 1; fi && export PATH="$PATH:$(pwd)/flutter/bin" && flutter config --enable-web && flutter pub get
   ```
4. **Build Command**: 
   ```bash
   export PATH="$PATH:$(pwd)/flutter/bin" && flutter build web --release
   ```
5. **Output Directory**: `build/web`

**重新部署**

#### 为什么脚本会失败？

- `.vercelignore` 中排除了 `scripts/` 目录
- Vercel 构建环境不包含脚本文件
- `chmod +x scripts/vercel_build.sh` 失败（文件不存在）
- 单行命令不依赖文件，直接在命令中执行，更可靠

#### 替代方案：使用 GitHub Actions（如果 Vercel 构建一直失败）

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

如果 Vercel 构建一直失败，使用 GitHub Actions 构建后部署：

1. **创建 `.github/workflows/build_flutter_web.yml`**:
   ```yaml
   name: Build Flutter Web
   on:
     push:
       branches: [ main ]
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: subosito/flutter-action@v2
           with:
             flutter-version: '3.24.0'
             channel: 'stable'
         - run: flutter pub get
         - run: flutter build web --release
         - uses: actions/upload-artifact@v3
           with:
             name: web-build
             path: build/web
   ```

2. **下载构建产物并手动部署到 Vercel**

**⚠️ 注意事项**:
- 首次部署需要 5-10 分钟（下载 Flutter SDK，约 1GB）
- Vercel 免费计划有构建时间限制
- 如果构建超时，考虑使用方案三或其他平台（Netlify、Firebase Hosting）

**📚 详细说明**: 查看 [Vercel部署问题解决方案](./docs/Vercel部署问题解决方案.md)

### Vercel 部署后显示 404

**问题**: Vercel 部署成功，但访问显示 404 错误

**原因**: Flutter Web 是 SPA（单页应用），需要配置路由重写规则

**解决**:
1. ✅ **确认 `vercel.json` 文件存在**（项目根目录）
   - 文件应该包含 `rewrites` 配置，将所有路由重写到 `/index.html`
   
2. **检查 Vercel 项目设置**:
   - 进入 Vercel Dashboard → 项目设置
   - **Output Directory**: `build/web`

3. **重新部署**:
   - 在 Vercel Dashboard 中点击 "Redeploy"
   - 或推送代码到 GitHub 触发自动部署

4. **验证 `vercel.json` 配置**:
   确保文件内容包含：
   ```json
   {
     "version": 2,
     "rewrites": [
       {
         "source": "/(.*)",
         "destination": "/index.html"
       }
     ]
   }
   ```

5. **检查构建日志**:
   - 在 Vercel Dashboard 中查看构建日志
   - 确认 `build/web` 目录中有 `index.html` 文件
   - 确认构建成功完成

6. **如果仍然 404**:
   - 清除浏览器缓存并刷新
   - 尝试无痕模式访问
   - 检查 Vercel 部署日志中的错误信息

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

- [快速开始指南](./QUICKSTART.md) - 开发环境搭建和本地 Docker 部署
- [健康检查优化方案](./docs/健康检查优化方案.md) - 健康检查优化说明
- [健康检查优化总结](./docs/健康检查优化总结.md) - 优化效果和使用建议

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

- [ ] 所有服务健康检查通过（Zeabur会自动处理，首次部署可能需要更长时间）
- [ ] 前端可以访问
- [ ] API 请求正常
- [ ] 数据库连接正常
- [ ] Storage 上传正常
- [ ] 端到端功能测试通过

> 💡 **提示**：项目已优化健康检查配置，服务启动期已增加到60秒，确保服务有充足的启动时间。如果遇到启动问题，请查看服务日志排查。

---

**文档版本**: v3.0  
**最后更新**: 2026-01-XX  
**维护者**: 开发团队

---

> 📝 **文档更新说明**: 
> - v3.0: 合并所有部署文档，统一到本文档
> - v2.0: 创建完整部署指南
> - v1.0: 初始版本
