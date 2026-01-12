# Zeabur 部署指南

> **平台**: Zeabur  
> **版本**: v2.0  
> **最后更新**: 2026-01-16  
> **注意**: 此文档已整合到 [完整部署指南](./DEPLOYMENT_GUIDE.md)，建议查看新文档

---

## 📌 重要提示

**此文档已整合到 [完整部署指南](./DEPLOYMENT_GUIDE.md)**，新文档包含：
- ✅ Supabase + Zeabur + Vercel 完整方案
- ✅ 更详细的步骤说明
- ✅ 更新的 Dockerfile 路径
- ✅ 完整的故障排查指南

**建议查看**: [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

---

# Zeabur 部署指南（旧版，保留用于参考）

> **平台**: Zeabur  
> **版本**: v1.0  
> **最后更新**: 2026-01-16

---

## 📋 部署选项分析

根据你的项目架构，在 Zeabur 上有两个部署选项：

### 选项 1：只部署 API Gateway（快速测试）

**适用场景**：
- ✅ 快速验证 API Gateway 功能
- ✅ 测试 API 路由和认证
- ✅ 开发环境测试

**限制**：
- ❌ 无法使用完整功能（Agent、Media、Data 服务未部署）
- ❌ 需要外部配置 PostgreSQL 和 Redis
- ❌ 无法生成图片/视频（Media Service 未部署）
- ❌ 无法处理对话和剧本（Agent Service 未部署）

**推荐指数**: ⭐⭐ (仅用于快速测试)

### 选项 2：完整微服务部署（推荐）

**适用场景**：
- ✅ 生产环境部署
- ✅ 完整功能使用
- ✅ 所有服务正常运行

**要求**：
- 需要 Zeabur 支持 Docker Compose 或多次部署
- 需要配置多个服务实例

**推荐指数**: ⭐⭐⭐⭐⭐ (生产环境推荐)

---

## 🎯 推荐方案

### ⚠️ 重要提示

**只部署 API Gateway 的限制**：
- API Gateway 需要转发请求到 Agent、Media、Data 服务
- 如果这些服务未部署，API Gateway 无法正常工作
- 所有业务功能（对话、图片生成、视频生成等）都无法使用

### 方案 A：使用 Supabase + 完整微服务部署（强烈推荐）⭐

**推荐指数**: ⭐⭐⭐⭐⭐

**优势**：
- ✅ 使用 Supabase 托管 PostgreSQL（自动备份、高可用、免费额度）
- ✅ 使用 Supabase Storage 替代 MinIO（对象存储，CDN 加速）
- ✅ 简化基础设施管理
- ✅ 降低运维成本

**步骤**：

1. **设置 Supabase 项目**
   - 在 [Supabase](https://supabase.com) 创建新项目
   - 获取数据库连接字符串
   - 创建 Storage Bucket（用于存储图片和视频）

2. **部署后端服务**（分别创建 4 个服务）
   - **API Gateway**：使用 `Dockerfile.zeabur`，端口 8000
   - **Agent Service**：使用 `backend/services/agent_service/Dockerfile`，端口 8001
   - **Media Service**：使用 `backend/services/media_service/Dockerfile`，端口 8002
   - **Data Service**：使用 `backend/services/data_service/Dockerfile`，端口 8003

3. **配置服务间通信**
   - 在 API Gateway 的环境变量中配置其他服务的 URL
   - 使用 Zeabur 的内部服务发现机制

4. **部署前端**
   - 使用 `frontend/Dockerfile`，端口 8080
   - 配置 `API_BASE_URL` 指向 API Gateway

### 方案 B：完整微服务部署（使用 Zeabur 托管服务）

**推荐指数**: ⭐⭐⭐⭐

**步骤**：

1. **部署基础设施**（使用 Zeabur 托管服务）
   - 创建 PostgreSQL 服务
   - 创建 Redis 服务
   - 创建 MinIO 服务（或使用外部对象存储）

2. **部署后端服务**（分别创建 4 个服务）
   - **API Gateway**：使用 `Dockerfile.zeabur`，端口 8000
   - **Agent Service**：使用 `backend/services/agent_service/Dockerfile`，端口 8001
   - **Media Service**：使用 `backend/services/media_service/Dockerfile`，端口 8002
   - **Data Service**：使用 `backend/services/data_service/Dockerfile`，端口 8003

3. **配置服务间通信**
   - 在 API Gateway 的环境变量中配置其他服务的 URL
   - 使用 Zeabur 的内部服务发现机制

4. **部署前端**
   - 使用 `frontend/Dockerfile`，端口 8080
   - 配置 `API_BASE_URL` 指向 API Gateway

### 方案 C：只部署 API Gateway（仅用于测试）

**推荐指数**: ⭐⭐

**适用场景**：
- 仅测试 API Gateway 的路由和认证功能
- 验证部署流程
- 开发环境快速测试

**限制**：
- ❌ 无法使用任何业务功能
- ❌ 所有 API 请求都会失败（因为后端服务不存在）
- ❌ 仅能访问 `/health`、`/docs` 等静态端点

**如果选择此方案**：
1. 使用 `Dockerfile.zeabur` 部署
2. 配置数据库和 Redis 连接（可以使用 Supabase）
3. 其他服务 URL 可以设置为占位符（请求会失败，但可以验证 API Gateway 本身是否正常）

---

## 🚀 部署步骤

### 方案 A：使用 Supabase 部署（推荐）

#### 1. 设置 Supabase 项目

1. **创建 Supabase 项目**
   - 访问 [Supabase](https://supabase.com)
   - 创建新项目
   - 等待项目初始化完成（约 2 分钟）

2. **获取数据库连接字符串**
   - 进入项目设置 → Database
   - 复制 "Connection string" → "URI"
   - 格式：`postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres`

3. **创建 Storage Bucket**
   - 进入 Storage → Buckets
   - 创建新 Bucket：`directorai-media`
   - 设置为 Public（如果需要公开访问）或 Private
   - 记录 Bucket 名称

4. **获取 Supabase 密钥**
   - 进入项目设置 → API
   - 复制以下信息：
     - `Project URL`: `https://[PROJECT-REF].supabase.co`
     - `anon key`: 用于客户端访问
     - `service_role key`: 用于服务端访问（⚠️ 保密）

#### 2. 配置环境变量

在 Zeabur 控制台为每个服务配置以下环境变量：

**所有后端服务通用配置**：

```env
# Supabase PostgreSQL 数据库
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Redis（使用 Zeabur 的 Redis 服务或 Upstash Redis）
REDIS_URL=redis://redis-host:6379/0

# JWT 配置
SECRET_KEY=your-strong-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# API 密钥
GLM_API_KEY=your-glm-api-key
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key
```

**Media Service 额外配置**：

```env
# Supabase Storage 配置（替代 MinIO）
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_KEY=[service_role key]
SUPABASE_BUCKET=directorai-media

# 或者继续使用 MinIO（如果已配置）
# MINIO_ENDPOINT=your-minio-endpoint
# MINIO_ACCESS_KEY=your-access-key
# MINIO_SECRET_KEY=your-secret-key
# MINIO_BUCKET=directorai-media
```

**API Gateway 配置**：

```env
# 服务地址（部署后获取）
AGENT_SERVICE_URL=https://agent-service.zeabur.app
MEDIA_SERVICE_URL=https://media-service.zeabur.app
DATA_SERVICE_URL=https://data-service.zeabur.app

# CORS 配置
CORS_ORIGINS=https://your-frontend-domain.com

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

#### 3. 部署服务

**部署顺序**：

1. **先部署 Agent、Media、Data 服务**
   - 分别创建 3 个服务
   - 使用对应的 Dockerfile
   - 配置环境变量（包含 Supabase 配置）

2. **获取服务 URL**
   - 在 Zeabur 控制台获取每个服务的 URL

3. **部署 API Gateway**
   - 使用 `Dockerfile.zeabur`
   - 配置其他服务的 URL
   - 配置 Supabase 数据库连接

4. **部署前端**
   - 使用 `frontend/Dockerfile`
   - 配置 `API_BASE_URL` 指向 API Gateway

#### 4. 数据库迁移

Supabase 使用标准的 PostgreSQL，可以直接运行 SQL 迁移脚本：

1. **方式 1：使用 Supabase SQL Editor**
   - 进入 Supabase Dashboard → SQL Editor
   - 复制 `backend/infrastructure/database/migrations/001_initial.sql` 的内容
   - 执行 SQL 脚本

2. **方式 2：使用 psql 命令行**
   ```bash
   psql "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres" \
     -f backend/infrastructure/database/migrations/001_initial.sql
   ```

#### 5. 配置 Storage 权限

在 Supabase Dashboard → Storage → Policies 中配置访问策略：

```sql
-- 允许公开读取
CREATE POLICY "Public Access" ON storage.objects
FOR SELECT USING (bucket_id = 'directorai-media');

-- 允许服务端写入（使用 service_role key）
-- 这个在代码中通过 Supabase 客户端处理
```

---

### 选项 1：只部署 API Gateway

#### 1. 使用 Dockerfile

项目根目录已包含 `Dockerfile.zeabur`，直接使用即可。

```dockerfile
# API Gateway Dockerfile for Zeabur
FROM python:3.11-slim

WORKDIR /app

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY backend/api_gateway/requirements.txt /app/requirements.txt

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制项目代码
COPY backend/api_gateway/ /app/api_gateway/
COPY backend/shared/ /app/shared/

# 设置Python路径
ENV PYTHONPATH=/app

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 启动命令
CMD ["uvicorn", "api_gateway.src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

#### 2. 配置环境变量

在 Zeabur 控制台配置以下环境变量：

```env
# 数据库（使用 Zeabur 的 PostgreSQL 服务）
DATABASE_URL=postgresql://user:password@postgres-host:5432/directorai

# Redis（使用 Zeabur 的 Redis 服务）
REDIS_URL=redis://redis-host:6379/0

# JWT 配置
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# 服务地址（如果其他服务在其他地方部署）
AGENT_SERVICE_URL=http://agent-service-url:8001
MEDIA_SERVICE_URL=http://media-service-url:8002
DATA_SERVICE_URL=http://data-service-url:8003

# CORS 配置
CORS_ORIGINS=https://your-frontend-domain.com

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60
```

#### 3. 部署到 Zeabur

1. 在 Zeabur 创建新项目
2. 连接 GitHub 仓库
3. 选择 Dockerfile 路径：`Dockerfile.zeabur`
4. 配置环境变量（见下方配置说明）
5. 部署

**⚠️ 注意**：部署后只能访问 `/health` 和 `/docs`，其他 API 会失败，因为后端服务未部署。

### 选项 2：完整微服务部署

#### 方案 2.1：分别部署多个服务（推荐）

在 Zeabur 上分别创建多个服务，每个服务使用对应的 Dockerfile：

1. **API Gateway 服务**
   - Dockerfile: `backend/api_gateway/Dockerfile`
   - 端口: 8000

2. **Agent Service**
   - Dockerfile: `backend/services/agent_service/Dockerfile`
   - 端口: 8001

3. **Media Service**
   - Dockerfile: `backend/services/media_service/Dockerfile`
   - 端口: 8002

4. **Data Service**
   - Dockerfile: `backend/services/data_service/Dockerfile`
   - 端口: 8003

5. **Frontend**
   - Dockerfile: `frontend/Dockerfile`
   - 端口: 8080

**服务间通信配置**：

在 Zeabur 中，服务间通信需要使用 Zeabur 提供的内部服务发现机制。

在 API Gateway 的环境变量中配置其他服务的 URL：

```env
# 方式1：使用 Zeabur 内部服务名（如果支持）
AGENT_SERVICE_URL=http://agent-service:8001
MEDIA_SERVICE_URL=http://media-service:8002
DATA_SERVICE_URL=http://data-service:8003

# 方式2：使用 Zeabur 提供的服务 URL（推荐）
# 在 Zeabur 控制台获取每个服务的 URL，然后配置
AGENT_SERVICE_URL=https://agent-service.zeabur.app
MEDIA_SERVICE_URL=https://media-service.zeabur.app
DATA_SERVICE_URL=https://data-service.zeabur.app
```

**部署顺序**：

1. 先部署 Agent、Media、Data 服务
2. 获取它们的服务 URL
3. 在 API Gateway 的环境变量中配置这些 URL
4. 最后部署 API Gateway

---

## 🔧 环境变量配置

### 使用 Supabase 的配置（推荐）

#### 必需环境变量

```env
# Supabase PostgreSQL 数据库
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres

# Redis 连接（使用 Zeabur 的 Redis 或 Upstash Redis）
REDIS_URL=redis://host:6379/0

# JWT 密钥
SECRET_KEY=your-strong-secret-key-here

# API 密钥
GLM_API_KEY=your-glm-api-key
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key

# Supabase Storage 配置（Media Service 需要）
SUPABASE_URL=https://[PROJECT-REF].supabase.co
SUPABASE_KEY=[service_role key]
SUPABASE_BUCKET=directorai-media
```

#### 可选环境变量

```env
# 服务端口
PORT=8000

# CORS 配置
CORS_ORIGINS=https://your-frontend-domain.com,https://www.your-domain.com

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60

# 如果使用 MinIO 而不是 Supabase Storage
MINIO_ENDPOINT=your-minio-endpoint
MINIO_ACCESS_KEY=your-access-key
MINIO_SECRET_KEY=your-secret-key
MINIO_BUCKET=directorai-media
```

### 使用 Zeabur 托管服务的配置

#### 必需环境变量

```env
# 数据库连接（使用 Zeabur 的 PostgreSQL）
DATABASE_URL=postgresql://user:password@host:5432/directorai

# Redis 连接（使用 Zeabur 的 Redis）
REDIS_URL=redis://host:6379/0

# JWT 密钥
SECRET_KEY=your-strong-secret-key-here

# API 密钥
GLM_API_KEY=your-glm-api-key
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key
```

#### 可选环境变量

```env
# 服务端口
PORT=8000

# CORS 配置
CORS_ORIGINS=https://your-frontend-domain.com,https://www.your-domain.com

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60

# MinIO 配置（如果使用外部对象存储）
MINIO_ENDPOINT=your-minio-endpoint
MINIO_ACCESS_KEY=your-access-key
MINIO_SECRET_KEY=your-secret-key
MINIO_BUCKET=directorai-media
```

---

## 📝 部署检查清单

### 部署前检查

- [ ] 已创建 Zeabur 账户
- [ ] 已连接 GitHub 仓库
- [ ] 已配置 PostgreSQL 服务（Zeabur 或外部）
- [ ] 已配置 Redis 服务（Zeabur 或外部）
- [ ] 已获取所有 API 密钥（GLM、Tuzi、Gemini）
- [ ] 已配置环境变量
- [ ] 已测试 Dockerfile 构建

### 部署后验证

- [ ] API Gateway 健康检查通过：`https://your-api-url/health`
- [ ] API 文档可访问：`https://your-api-url/docs`
- [ ] 数据库连接正常
- [ ] Redis 连接正常
- [ ] 前端可以访问后端 API
- [ ] CORS 配置正确

---

## 🐛 常见问题

### 1. 服务无法启动

**问题**: 容器启动失败

**解决**:
- 检查环境变量配置
- 查看 Zeabur 日志
- 确认端口配置正确

### 2. 数据库连接失败

**问题**: `sqlalchemy.exc.OperationalError`

**解决**:
- 检查 `DATABASE_URL` 格式
- 确认数据库服务已启动
- 检查网络连接

### 3. 服务间通信失败

**问题**: API Gateway 无法连接到其他服务

**解决**:
- 确认所有服务都已部署
- 检查服务 URL 配置
- 使用 Zeabur 的内部服务发现机制

### 4. CORS 错误

**问题**: 前端无法访问 API

**解决**:
- 配置 `CORS_ORIGINS` 环境变量
- 添加前端域名到允许列表

---

## 💡 最佳实践建议

### 1. 使用 Supabase（强烈推荐）

**优势**：
- ✅ **免费额度**：500MB 数据库 + 1GB 存储（适合开发和小型项目）
- ✅ **自动备份**：每日自动备份，可恢复到任意时间点
- ✅ **高可用**：99.9% 可用性保证
- ✅ **CDN 加速**：Storage 文件自动 CDN 加速
- ✅ **易于管理**：Web 界面管理数据库和存储
- ✅ **实时功能**：支持实时订阅（未来可扩展）

**配置步骤**：
1. 在 Supabase 创建项目
2. 获取数据库连接字符串
3. 创建 Storage Bucket
4. 配置环境变量
5. 运行数据库迁移

### 2. 使用 Zeabur 托管服务（备选方案）

- ✅ 使用 Zeabur 的 PostgreSQL 服务（自动备份、高可用）
- ✅ 使用 Zeabur 的 Redis 服务（自动管理）
- ✅ 使用 Zeabur 的环境变量管理（安全存储密钥）

### 3. 分阶段部署

1. **测试阶段**：先部署 API Gateway，验证基础功能
2. **开发阶段**：逐步添加其他服务
3. **生产阶段**：完整部署所有服务

### 4. 监控和日志

- 配置 Zeabur 的日志查看功能
- 设置健康检查
- 配置告警通知
- 使用 Supabase Dashboard 监控数据库和存储使用情况

### 5. 安全配置

- 使用强密钥（SECRET_KEY）
- 配置正确的 CORS 域名
- 启用 HTTPS（Zeabur 自动提供）
- 定期更新依赖
- 保护 Supabase service_role key（仅在服务端使用）
- 使用 Supabase Row Level Security (RLS) 保护数据（可选）

---

## 🔗 相关文档

- [统一部署指南](./DEPLOYMENT.md) - 本地 Docker 部署
- [Supabase 集成指南](./SUPABASE_SETUP.md) - Supabase 详细配置说明
- [快速开始指南](./QUICKSTART.md) - 开发环境搭建
- [后端开发文档](./backend/DEVELOPMENT.md) - 后端开发指南

---

## 📞 支持

如果遇到部署问题：

1. 查看 Zeabur 官方文档
2. 检查项目日志
3. 参考 [DEPLOYMENT.md](./DEPLOYMENT.md) 中的故障排查部分

---

**文档版本**: v1.0  
**最后更新**: 2026-01-16  
**维护者**: 开发团队
