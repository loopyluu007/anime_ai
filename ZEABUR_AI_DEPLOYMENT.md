# Zeabur AI 自动部署指南

> **平台**: Zeabur  
> **目标**: 自动部署 4 个后端微服务  
> **版本**: v1.0  
> **最后更新**: 2026-01-16

---

## 🎯 文档职责说明

### 🤖 Zeabur AI 的工作范围

**Zeabur AI 需要自动完成的任务**（标记为 `🤖 Zeabur AI 任务`）:
- ✅ 在 Zeabur 平台连接 GitHub 仓库
- ✅ 部署 4 个后端服务（Agent、Media、Data、API Gateway）
- ✅ 配置每个服务的环境变量
- ✅ 验证服务部署状态

### 🔵 Supabase 配置（非 AI 任务）

**Supabase 配置**（标记为 `🔵 SUPABASE`）:
- ⚠️ **需要在 Supabase Dashboard 手动完成**
- ⚠️ **Zeabur AI 无法直接操作 Supabase**
- ⚠️ **需要用户或人类管理员完成**
- ✅ 配置完成后，获取的信息用于 Zeabur 服务配置

### ⚡ Vercel 配置（本文档不涉及）

**Vercel 前端部署**:
- ⚠️ **本文档专注于后端服务部署**
- ⚠️ **前端部署请参考 `DEPLOYMENT_GUIDE.md`**
- ✅ Zeabur AI 只需完成后端部署

---

## 📋 部署概述

本指南包含在 Zeabur 平台上自动部署 AI漫导 后端服务的完整信息，包含 4 个微服务：

1. **API Gateway** - 端口 8000，统一入口和路由转发
2. **Agent Service** - 端口 8001，处理对话、任务、剧本业务
3. **Media Service** - 端口 8002，处理图片和视频生成
4. **Data Service** - 端口 8003，处理用户数据管理

**数据库和存储**: 使用 Supabase (PostgreSQL + Storage)

---

## 🏗️ 架构说明

```
用户请求
  ↓
API Gateway (端口 8000)
  ├─→ Agent Service (端口 8001)
  ├─→ Media Service (端口 8002)
  └─→ Data Service (端口 8003)
       ↓
    Supabase
  - PostgreSQL 数据库
  - Storage 对象存储
```

---

## 📦 前置准备

---

### 🔵 SUPABASE 配置（必须在 Supabase 平台手动完成）

> **⚠️ 重要**: 以下配置需要在 Supabase Dashboard 中手动完成，这部分不是 Zeabur AI 的工作。配置完成后，获取相关信息用于后续 Zeabur 服务部署。

#### 1.1 创建 Supabase 项目

1. 访问 https://supabase.com
2. 创建新项目，项目名: `director-ai`
3. 设置数据库密码（⚠️ 务必保存）
4. 选择区域（推荐: Southeast Asia (Singapore)）
5. 等待项目初始化完成（约 2 分钟）

#### 1.2 获取数据库连接字符串

1. 进入 Supabase Dashboard → Settings → Database
2. 找到 "Connection string" → "URI"
3. 复制连接字符串，格式:
   ```
   postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
   ```
4. 将 `[PASSWORD]` 替换为创建项目时设置的密码

#### 1.3 创建 Storage Bucket

1. 进入 Supabase Dashboard → Storage
2. 点击 "New bucket"
3. 配置:
   - **Name**: `directorai-media`
   - **Public bucket**: ✅ 选择 Public（用于公开访问图片/视频）
4. 点击 "Create bucket"

#### 1.4 获取 Supabase API 密钥

1. 进入 Supabase Dashboard → Settings → API
2. 复制以下信息:
   - **Project URL**: `https://[PROJECT-REF].supabase.co`
   - **service_role key**: 用于服务端访问（⚠️ 保密，仅后端使用）

#### 1.5 运行数据库迁移

**方式 1: Supabase SQL Editor（推荐）**

1. 进入 Supabase Dashboard → SQL Editor
2. 点击 "New query"
3. 复制以下 SQL 内容并执行:

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

### 2. 准备 API 密钥

> **⚠️ 重要**: 以下 API 密钥需要用户预先准备好，不是 Zeabur AI 的工作。

准备以下 API 密钥（部署时需要配置）:

- **GLM_API_KEY**: 智谱 AI API 密钥
- **TUZI_API_KEY**: 图子视频生成 API 密钥
- **GEMINI_API_KEY**: Google Gemini 图片生成 API 密钥

---

## 🤖 ZEABUR AI 自动部署步骤

> **⚠️ 核心任务**: 以下部分是 Zeabur AI 需要自动完成的工作。AI 需要按照以下步骤在 Zeabur 平台上部署 4 个后端服务。

---

### 阶段 1: 连接 GitHub 仓库

> **🤖 Zeabur AI 任务**: 在 Zeabur 平台上连接 GitHub 仓库

1. 登录 Zeabur Dashboard: https://dash.zeabur.com
2. 点击 "New Project"
3. 选择 "Import from GitHub"
4. 选择你的仓库: `anime_ai`
5. 授权 Zeabur 访问仓库

---

### 阶段 2: 部署 Agent Service（服务 1/4）

> **🤖 Zeabur AI 任务**: 部署第一个后端服务 - Agent Service

#### 2.1 创建服务

1. 在 Zeabur 项目中点击 "New Service"
2. 选择 GitHub 仓库: `anime_ai`
3. 配置服务:
   - **Service Name**: `agent-service`
   - **Dockerfile Path**: `backend/services/agent_service/Dockerfile.zeabur`
   - **Port**: `8001`（Zeabur 会自动检测）

#### 2.2 配置环境变量

在服务设置中添加以下环境变量:

```env
# 数据库配置（Supabase PostgreSQL）
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# JWT 配置
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# API 密钥
GLM_API_KEY=your-glm-api-key

# 服务配置
PORT=8001
```

**⚠️ 重要**: 将 `[YOUR-PASSWORD]` 和 `[PROJECT-REF]` 替换为实际的 Supabase 项目信息。

#### 2.3 部署

1. 点击 "Deploy"
2. 等待构建和部署完成（约 3-5 分钟）
3. 部署成功后，记录服务 URL: `https://agent-service-[hash].zeabur.app`

---

### 阶段 3: 部署 Media Service（服务 2/4）

> **🤖 Zeabur AI 任务**: 部署第二个后端服务 - Media Service（需要 Supabase Storage 配置）

#### 3.1 创建服务

1. 在 Zeabur 项目中点击 "New Service"
2. 选择 GitHub 仓库: `anime_ai`
3. 配置服务:
   - **Service Name**: `media-service`
   - **Dockerfile Path**: `backend/services/media_service/Dockerfile.zeabur`
   - **Port**: `8002`

#### 3.2 配置环境变量

```env
# 数据库配置（Supabase PostgreSQL）
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Supabase Storage 配置
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_KEY=[service_role key]
SUPABASE_BUCKET=directorai-media

# JWT 配置
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# API 密钥
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key

# 服务配置
PORT=8002
```

**⚠️ 重要**: 
- `[PROJECT-REF]` 替换为 Supabase 项目引用
- `[service_role key]` 替换为 Supabase service_role 密钥

#### 3.3 部署

1. 点击 "Deploy"
2. 等待构建和部署完成
3. 记录服务 URL: `https://media-service-[hash].zeabur.app`

---

### 阶段 4: 部署 Data Service（服务 3/4）

> **🤖 Zeabur AI 任务**: 部署第三个后端服务 - Data Service

#### 4.1 创建服务

1. 在 Zeabur 项目中点击 "New Service"
2. 选择 GitHub 仓库: `anime_ai`
3. 配置服务:
   - **Service Name**: `data-service`
   - **Dockerfile Path**: `backend/services/data_service/Dockerfile.zeabur`
   - **Port**: `8003`

#### 4.2 配置环境变量

```env
# 数据库配置（Supabase PostgreSQL）
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# JWT 配置
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# 服务配置
PORT=8003
```

#### 4.3 部署

1. 点击 "Deploy"
2. 等待构建和部署完成
3. 记录服务 URL: `https://data-service-[hash].zeabur.app`

---

### 阶段 5: 部署 API Gateway（服务 4/4，最后部署）

> **🤖 Zeabur AI 任务**: 部署第四个也是最后一个后端服务 - API Gateway（需要配置其他服务的 URL）

**⚠️ 重要**: 必须先部署 Agent、Media、Data 服务，获取它们的 URL 后才能部署 API Gateway。

#### 5.1 创建服务

1. 在 Zeabur 项目中点击 "New Service"
2. 选择 GitHub 仓库: `anime_ai`
3. 配置服务:
   - **Service Name**: `api-gateway`
   - **Dockerfile Path**: `backend/api_gateway/Dockerfile.zeabur`
   - **Port**: `8000`

#### 5.2 配置环境变量

```env
# 数据库配置（Supabase PostgreSQL）
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# 后端服务 URL（使用阶段 2-4 中记录的服务 URL）
AGENT_SERVICE_URL=https://agent-service-[hash].zeabur.app
MEDIA_SERVICE_URL=https://media-service-[hash].zeabur.app
DATA_SERVICE_URL=https://data-service-[hash].zeabur.app

# JWT 配置（必须与其他服务保持一致）
SECRET_KEY=your-strong-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# CORS 配置（前端域名）
CORS_ORIGINS=https://your-frontend-domain.com,https://www.your-domain.com

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60

# 服务配置
PORT=8000
```

**⚠️ 重要**: 
- 将所有 `[hash]` 替换为实际部署后的服务 URL 哈希值
- `SECRET_KEY` 必须与其他服务完全相同
- `CORS_ORIGINS` 配置前端域名，多个域名用逗号分隔

#### 5.3 部署

1. 点击 "Deploy"
2. 等待构建和部署完成
3. 记录服务 URL: `https://api-gateway-[hash].zeabur.app`（这是前端需要配置的 API 地址）

---

## ✅ 验证部署

> **🤖 Zeabur AI 任务**: 验证所有服务是否部署成功并正常运行

### 1. 验证各服务健康状态

访问每个服务的健康检查端点:

```bash
# Agent Service
curl https://agent-service-[hash].zeabur.app/health

# Media Service
curl https://media-service-[hash].zeabur.app/health

# Data Service
curl https://data-service-[hash].zeabur.app/health

# API Gateway
curl https://api-gateway-[hash].zeabur.app/health
```

预期响应: `{"status": "healthy"}` 或类似成功消息

### 2. 验证 API Gateway 路由

访问 API Gateway 的 API 文档:

```
https://api-gateway-[hash].zeabur.app/docs
```

应该能看到完整的 API 文档和接口列表。

### 3. 验证数据库连接

检查 Zeabur 服务日志，确认没有数据库连接错误。

---

## 🔧 环境变量完整清单

> **🤖 Zeabur AI 任务**: 使用以下环境变量配置各个服务

### 所有服务通用环境变量

| 变量名 | 必需 | 说明 | 示例值 |
|--------|------|------|--------|
| `DATABASE_URL` | ✅ | Supabase PostgreSQL 连接字符串 | `postgresql://postgres:password@db.xxx.supabase.co:5432/postgres` |
| `SECRET_KEY` | ✅ | JWT 密钥（所有服务必须相同） | `your-strong-secret-key-here` |
| `ALGORITHM` | ✅ | JWT 算法 | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | ✅ | Token 过期时间（分钟） | `60` |

### Agent Service 专用

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `GLM_API_KEY` | ✅ | 智谱 AI API 密钥 |
| `PORT` | ✅ | 服务端口 | `8001` |

### Media Service 专用

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `SUPABASE_URL` | ✅ | Supabase 项目 URL |
| `SUPABASE_KEY` | ✅ | Supabase service_role 密钥 |
| `SUPABASE_BUCKET` | ✅ | Storage Bucket 名称 | `directorai-media` |
| `TUZI_API_KEY` | ✅ | 图子视频生成 API 密钥 |
| `GEMINI_API_KEY` | ✅ | Google Gemini API 密钥 |
| `PORT` | ✅ | 服务端口 | `8002` |

### Data Service 专用

| 变量名 | 必需 | 说明 |
|--------|------|------|
| `PORT` | ✅ | 服务端口 | `8003` |

### API Gateway 专用

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

---

## 📁 Dockerfile 路径

> **🤖 Zeabur AI 任务**: 使用以下 Dockerfile 路径部署各个服务

| 服务 | Dockerfile 路径 | Zeabur AI 操作 |
|------|----------------|---------------|
| API Gateway | `backend/api_gateway/Dockerfile.zeabur` | ✅ 在 Zeabur 中指定此路径 |
| Agent Service | `backend/services/agent_service/Dockerfile.zeabur` | ✅ 在 Zeabur 中指定此路径 |
| Media Service | `backend/services/media_service/Dockerfile.zeabur` | ✅ 在 Zeabur 中指定此路径 |
| Data Service | `backend/services/data_service/Dockerfile.zeabur` | ✅ 在 Zeabur 中指定此路径 |

---

## 🐛 故障排查

### 问题 1: 服务无法启动

**症状**: Zeabur 部署失败或服务无法启动

**解决**:
1. 检查 Dockerfile 路径是否正确
2. 查看 Zeabur 构建日志，查找错误信息
3. 确认环境变量配置完整且格式正确
4. 检查端口配置（Zeabur 会自动映射，但需要正确设置 EXPOSE）

### 问题 2: 数据库连接失败

**症状**: 日志显示 `sqlalchemy.exc.OperationalError: could not connect to server`

**解决**:
1. 检查 `DATABASE_URL` 格式是否正确
2. 确认 Supabase 项目密码是否正确（注意 URL 编码特殊字符）
3. 检查 Supabase 项目状态是否正常
4. 确认网络连接正常

### 问题 3: API Gateway 无法连接到后端服务

**症状**: API Gateway 返回 502 或 503 错误

**解决**:
1. 确认所有后端服务（Agent、Media、Data）都已部署成功
2. 检查服务 URL 配置是否正确（使用完整的 HTTPS URL）
3. 确认服务健康检查通过（访问 `/health` 端点）
4. 检查服务日志，查找连接错误

### 问题 4: Media Service Storage 上传失败

**症状**: 图片/视频上传失败

**解决**:
1. 检查 `SUPABASE_KEY` 是否正确（使用 service_role key）
2. 确认 `SUPABASE_BUCKET` 名称正确: `directorai-media`
3. 检查 Supabase Dashboard 中的 Storage 权限策略
4. 查看 Supabase Dashboard 中的错误日志

### 问题 5: CORS 错误

**症状**: 前端访问 API 时出现 CORS 错误

**解决**:
1. 在 API Gateway 环境变量中配置 `CORS_ORIGINS`，包含前端域名
2. 多个域名用逗号分隔
3. 确认前端使用正确的 API Gateway URL
4. 检查浏览器控制台的具体错误信息

---

## 📊 部署顺序总结

1. ✅ **完成 Supabase 配置**（数据库、Storage、迁移）
2. ✅ **部署 Agent Service**（端口 8001）
3. ✅ **部署 Media Service**（端口 8002）
4. ✅ **部署 Data Service**（端口 8003）
5. ✅ **记录所有服务 URL**
6. ✅ **部署 API Gateway**（端口 8000，配置其他服务 URL）
7. ✅ **验证所有服务健康状态**
8. ✅ **配置前端连接 API Gateway**

---

## 🔗 相关资源

- **Zeabur 官方文档**: https://zeabur.com/docs
- **Supabase 官方文档**: https://supabase.com/docs
- **项目 GitHub 仓库**: （你的仓库地址）

---

**文档版本**: v1.0  
**最后更新**: 2026-01-16  
**维护者**: 开发团队

---

## 📝 AI 部署检查清单

在自动部署时，请按以下顺序执行:

### 前置条件检查
- [ ] Supabase 项目已创建
- [ ] 数据库迁移已执行
- [ ] Storage Bucket 已创建
- [ ] 已获取所有 API 密钥（GLM、TUZI、GEMINI）
- [ ] 已准备 SECRET_KEY（JWT 密钥）

### 部署执行
- [ ] Agent Service 已部署（端口 8001）
- [ ] Media Service 已部署（端口 8002）
- [ ] Data Service 已部署（端口 8003）
- [ ] 已记录所有服务 URL
- [ ] API Gateway 已部署（端口 8000）
- [ ] 所有服务健康检查通过

### 验证测试
- [ ] 各服务 `/health` 端点正常
- [ ] API Gateway `/docs` 可访问
- [ ] 数据库连接正常
- [ ] Storage 上传功能正常
- [ ] 服务间通信正常

---

**注意**: 本文档专为 Zeabur AI 自动部署设计，包含所有必要信息。AI 只需按照本文档的步骤顺序执行即可完成部署。
