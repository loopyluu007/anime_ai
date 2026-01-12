# AI漫导本地部署指南

> **注意**: 此文档用于本地 Docker Compose 部署  
> **云部署**: 请查看 [完整部署指南](./DEPLOYMENT_GUIDE.md)（Supabase + Zeabur + Vercel）

本文档说明如何使用项目根目录的统一部署脚本进行本地前后端一体化部署。

## 📋 目录结构

```
项目根目录/
├── docker-compose.yml      # 统一的 Docker Compose 配置（包含前后端所有服务）
├── start.sh / start.bat     # 统一启动脚本
├── stop.sh / stop.bat       # 统一停止脚本
├── .env.example            # 环境变量配置示例
└── .env                    # 环境变量配置文件（需要创建）
```

## 🚀 快速开始

### 部署方式选择

#### 方式 1：使用 Supabase（推荐用于云部署）⭐

**优势**：
- ✅ 无需自建数据库和存储
- ✅ 自动备份和高可用
- ✅ 免费额度适合开发和小型项目
- ✅ CDN 加速存储文件

**适用场景**：
- 云平台部署（Zeabur、Vercel、Railway 等）
- 快速上线
- 降低运维成本

详细说明请查看 [Zeabur 部署指南](./ZEABUR_DEPLOYMENT.md) 中的 Supabase 配置部分。

#### 方式 2：使用 Docker Compose（本地/自建服务器）

**优势**：
- ✅ 完全控制所有服务
- ✅ 适合本地开发
- ✅ 适合私有部署

**适用场景**：
- 本地开发环境
- 私有服务器部署
- 需要完全控制基础设施

### 1. 环境准备

确保已安装：
- Docker >= 20.10
- Docker Compose >= 2.0（或 docker-compose >= 1.29）

### 2. 配置环境变量

#### 使用 Supabase（推荐）

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑 .env 文件，配置必要的环境变量
# 至少需要配置：
# - DATABASE_URL (Supabase PostgreSQL)
# - SUPABASE_URL
# - SUPABASE_KEY
# - SUPABASE_BUCKET
# - GLM_API_KEY
# - TUZI_API_KEY
# - GEMINI_API_KEY
# - SECRET_KEY
```

#### 使用 Docker Compose（本地部署）

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑 .env 文件，配置必要的环境变量
# 至少需要配置：
# - GLM_API_KEY
# - TUZI_API_KEY
# - GEMINI_API_KEY
# - SECRET_KEY
# 数据库和 Redis 会自动启动（Docker Compose）
```

### 3. 启动服务

#### Linux/Mac

```bash
# 启动所有服务（生产环境）
./start.sh prod

# 或指定组件
./start.sh prod all          # 启动所有服务（默认）
./start.sh prod frontend     # 只启动前端
./start.sh prod backend      # 只启动后端

# 开发环境（只启动基础设施）
./start.sh dev
```

#### Windows

```cmd
# 启动所有服务（生产环境）
start.bat prod

# 或指定组件
start.bat prod all          # 启动所有服务（默认）
start.bat prod frontend     # 只启动前端
start.bat prod backend      # 只启动后端

# 开发环境（只启动基础设施）
start.bat dev
```

### 4. 停止服务

#### Linux/Mac

```bash
./stop.sh all       # 停止所有服务（默认）
./stop.sh frontend  # 只停止前端
./stop.sh backend   # 只停止后端
```

#### Windows

```cmd
stop.bat all       # 停止所有服务（默认）
stop.bat frontend  # 只停止前端
stop.bat backend   # 只停止后端
```

## 📦 服务说明

### 生产环境服务

| 服务 | 端口 | 说明 | 访问地址 |
|------|------|------|----------|
| Frontend | 8080 | Flutter Web 前端 | http://localhost:8080 |
| API Gateway | 8000 | 统一API入口 | http://localhost:8000 |
| Agent Service | 8001 | Agent业务服务 | http://localhost:8001 |
| Media Service | 8002 | 媒体服务（图片/视频生成） | http://localhost:8002 |
| Data Service | 8003 | 数据服务（用户数据/分析） | http://localhost:8003 |
| PostgreSQL | 5432 | 数据库 | localhost:5432 |
| Redis | 6379 | 缓存 | localhost:6379 |
| MinIO | 9000 | 对象存储 | http://localhost:9000 |
| MinIO Console | 9001 | MinIO管理界面 | http://localhost:9001 |

### 开发环境服务

开发环境只启动基础设施服务（PostgreSQL、Redis、MinIO），业务服务需要在本地运行。

## 🔧 常用命令

### 查看服务状态

```bash
docker-compose ps
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f frontend
docker-compose logs -f api_gateway
docker-compose logs -f agent_service
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart frontend
docker-compose restart api_gateway
```

### 重新构建

```bash
# 重新构建并启动所有服务
docker-compose up -d --build

# 重新构建特定服务
docker-compose up -d --build frontend
```

### 进入容器

```bash
# 进入PostgreSQL容器
docker-compose exec postgres psql -U directorai -d directorai

# 进入Redis容器
docker-compose exec redis redis-cli
```

## 🗄️ 数据持久化

所有数据都存储在 Docker volumes 中：

- `postgres_data` - PostgreSQL 数据
- `redis_data` - Redis 数据
- `minio_data` - MinIO 对象存储数据

### 备份数据

```bash
# 备份PostgreSQL
docker-compose exec postgres pg_dump -U directorai directorai > backup.sql

# 备份Redis
docker-compose exec redis redis-cli SAVE
docker cp directorai_redis:/data/dump.rdb ./redis_backup.rdb
```

### 清理数据（⚠️ 危险操作）

```bash
# 停止并删除所有容器和数据卷
docker-compose down -v
```

## 🔍 健康检查

所有服务都配置了健康检查，可以通过以下方式查看：

```bash
# 查看服务健康状态
docker-compose ps

# 手动检查健康状态
curl http://localhost:8000/health  # API Gateway
curl http://localhost:8001/health  # Agent Service
curl http://localhost:8002/health  # Media Service
curl http://localhost:8003/health  # Data Service
curl http://localhost:8080/       # Frontend
```

## 🐛 故障排查

### 服务无法启动

1. 检查端口是否被占用
2. 检查环境变量配置是否正确（特别是 API 密钥）
3. 查看服务日志：`docker-compose logs [service_name]`

### 数据库连接失败

1. 检查PostgreSQL是否正常启动：`docker-compose ps postgres`
2. 检查数据库连接字符串是否正确
3. 查看PostgreSQL日志：`docker-compose logs postgres`

### 服务间通信失败

1. 确保所有服务在同一网络（`directorai_network`）
2. 检查服务依赖关系（depends_on）
3. 使用服务名而非localhost进行服务间通信

### 前端无法连接后端

1. 检查 `.env` 文件中的 `API_BASE_URL` 和 `WS_URL` 配置
2. 确保 API Gateway 正常运行
3. 检查 CORS 配置

## 📝 环境变量说明

### 使用 Supabase 的配置

#### 必需配置

- `DATABASE_URL` - Supabase PostgreSQL 连接字符串
  - 格式：`postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres`
  - 获取方式：Supabase Dashboard → Settings → Database → Connection string
- `SUPABASE_URL` - Supabase 项目 URL
  - 格式：`https://[PROJECT-REF].supabase.co`
- `SUPABASE_KEY` - Supabase service_role key（用于服务端访问）
  - 获取方式：Supabase Dashboard → Settings → API → service_role key
- `SUPABASE_BUCKET` - Storage Bucket 名称（默认：`directorai-media`）
- `GLM_API_KEY` - 智谱 AI API 密钥（用于对话和剧本生成）
- `TUZI_API_KEY` - 图子 API 密钥（用于视频生成）
- `GEMINI_API_KEY` - Google Gemini API 密钥（用于图片生成）
- `SECRET_KEY` - JWT 密钥（生产环境请使用强密钥）

#### 可选配置

- `REDIS_URL` - Redis 连接（如果使用 Redis，默认：`redis://localhost:6379/0`）
- `API_BASE_URL` - 前端 API 基础 URL（默认：http://localhost:8000/api/v1）
- `WS_URL` - 前端 WebSocket URL（默认：ws://localhost:8000/ws）
- `FRONTEND_PORT` - 前端端口（默认：8080）
- `API_GATEWAY_PORT` - API 网关端口（默认：8000）
- `CORS_ORIGINS` - CORS 允许的来源（默认：*）

### 使用 Docker Compose 的配置

#### 必需配置

- `GLM_API_KEY` - 智谱 AI API 密钥（用于对话和剧本生成）
- `TUZI_API_KEY` - 图子 API 密钥（用于视频生成）
- `GEMINI_API_KEY` - Google Gemini API 密钥（用于图片生成）
- `SECRET_KEY` - JWT 密钥（生产环境请使用强密钥）

#### 可选配置

- `POSTGRES_USER` - PostgreSQL 用户名（默认：directorai）
- `POSTGRES_PASSWORD` - PostgreSQL 密码（默认：directorai）
- `POSTGRES_DB` - PostgreSQL 数据库名（默认：directorai）
- `REDIS_PORT` - Redis 端口（默认：6379）
- `MINIO_ROOT_USER` - MinIO 用户名（默认：minioadmin）
- `MINIO_ROOT_PASSWORD` - MinIO 密码（默认：minioadmin）
- `API_BASE_URL` - 前端 API 基础 URL（默认：http://localhost:8000/api/v1）
- `WS_URL` - 前端 WebSocket URL（默认：ws://localhost:8000/ws）
- `FRONTEND_PORT` - 前端端口（默认：8080）
- `API_GATEWAY_PORT` - API 网关端口（默认：8000）
- `CORS_ORIGINS` - CORS 允许的来源（默认：*）

完整的环境变量列表请参考 `.env.example` 文件。

## 🔐 生产环境注意事项

1. **修改默认密码**：
   - PostgreSQL、Redis、MinIO 的默认密码
   - 使用强密钥（SECRET_KEY）

2. **配置正确的 CORS 域名**：
   - 修改 `CORS_ORIGINS` 为实际的前端域名
   - 不要使用 `*` 在生产环境

3. **启用 HTTPS**：
   - 使用反向代理（Nginx/Traefik）配置 HTTPS
   - 配置 SSL 证书

4. **数据安全**：
   - 定期备份数据库
   - 保护 API 密钥
   - 使用环境变量而非硬编码

5. **性能优化**：
   - 根据实际负载调整资源限制
   - 配置适当的健康检查间隔
   - 使用生产级数据库配置

## 🐳 前端独立部署

> **注意**：推荐使用统一部署脚本 `./start.sh prod`，如需单独部署前端，可使用以下方式。

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+（可选）

### 快速启动

```bash
# 在项目根目录执行

# 方式1：使用统一脚本（推荐）
./start.sh prod frontend    # Linux/Mac
start.bat prod frontend     # Windows

# 方式2：使用 Docker Compose
docker-compose -f frontend/docker-compose.yml up -d

# 方式3：使用 Docker 命令
docker build -t director-ai-frontend -f frontend/Dockerfile .
docker run -d -p 8080:80 --name director-ai-frontend director-ai-frontend
```

访问: http://localhost:8080

### 构建镜像

#### 基本构建

```bash
# 在项目根目录执行
docker build -t director-ai-frontend -f frontend/Dockerfile .
```

#### 构建参数

```bash
# 指定 Flutter 版本
docker build \
  --build-arg FLUTTER_VERSION=stable \
  -t director-ai-frontend \
  -f frontend/Dockerfile .
```

#### 多阶段构建说明

Dockerfile 使用多阶段构建：

1. **构建阶段**: 使用 Flutter SDK 构建 Web 应用
2. **运行阶段**: 使用轻量级 Nginx 提供静态文件

优势：
- 最终镜像体积小（~50MB）
- 构建和运行环境分离
- 安全性更高

### 运行容器

#### 基本运行

```bash
docker run -d \
  -p 8080:80 \
  --name director-ai-frontend \
  director-ai-frontend
```

#### 自定义端口

```bash
docker run -d \
  -p 3000:80 \
  --name director-ai-frontend \
  director-ai-frontend
```

#### 挂载自定义配置

```bash
docker run -d \
  -p 8080:80 \
  -v $(pwd)/frontend/nginx.conf:/etc/nginx/conf.d/default.conf \
  --name director-ai-frontend \
  director-ai-frontend
```

### Docker Compose 管理

#### 使用 Docker Compose（推荐）

```bash
# 在项目根目录执行
docker-compose -f frontend/docker-compose.yml up -d
```

#### 查看日志

```bash
# 在项目根目录执行
docker-compose -f frontend/docker-compose.yml logs -f frontend
```

#### 停止服务

```bash
# 在项目根目录执行
docker-compose -f frontend/docker-compose.yml down
```

#### 重新构建

```bash
# 在项目根目录执行
docker-compose -f frontend/docker-compose.yml up -d --build
```

### 生产环境部署

#### 1. 使用 HTTPS

```nginx
# nginx-ssl.conf
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    
    root /usr/share/nginx/html;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

#### 2. 环境变量配置

创建 `.env` 文件：

```env
API_BASE_URL=https://api.your-domain.com/api/v1
WS_URL=wss://api.your-domain.com/ws
```

#### 3. 生产环境 Docker Compose

```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ..
      dockerfile: frontend/Dockerfile
    container_name: director_ai_frontend
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx-ssl.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
    environment:
      - API_BASE_URL=https://api.your-domain.com/api/v1
      - WS_URL=wss://api.your-domain.com/ws
    restart: always
    networks:
      - director_ai_network
```

#### 4. 使用反向代理（推荐）

使用 Nginx 或 Traefik 作为反向代理：

```nginx
# 反向代理配置
upstream frontend {
    server director_ai_frontend:80;
}

server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 自定义配置

#### 修改 Nginx 配置

1. 编辑 `frontend/nginx.conf`
2. 重新构建镜像或挂载配置文件

```bash
docker run -d \
  -p 8080:80 \
  -v $(pwd)/frontend/nginx.conf:/etc/nginx/conf.d/default.conf \
  director-ai-frontend
```

#### 添加环境变量

在构建时注入环境变量（需要在代码中读取）：

```dart
// lib/core/config/api_config.dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8001/api/v1',
  );
}
```

构建时传递：

```bash
docker build \
  --build-arg API_BASE_URL=https://api.example.com/api/v1 \
  -t director-ai-frontend \
  -f frontend/Dockerfile .
```

### 前端 Docker 常见问题

#### 1. 构建失败 - Flutter 版本不兼容

**问题**: `flutter build web` 失败

**解决**:
```bash
# 检查 Flutter 版本
docker run --rm ghcr.io/cirruslabs/flutter:stable flutter --version

# 使用特定版本
FROM ghcr.io/cirruslabs/flutter:3.16.0 AS build
```

#### 2. 路由 404 错误

**问题**: 刷新页面后出现 404

**解决**: 确保 Nginx 配置包含：
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

#### 3. API 请求跨域错误

**问题**: CORS 错误

**解决**: 
- 在后端配置 CORS
- 或使用 Nginx 反向代理

#### 4. 静态资源加载失败

**问题**: CSS/JS 文件 404

**解决**: 检查构建输出路径：
```bash
# 确认构建产物位置
docker run --rm director-ai-frontend ls -la /usr/share/nginx/html
```

#### 5. 镜像体积过大

**问题**: 镜像超过 1GB

**解决**: 
- 使用多阶段构建（已实现）
- 清理构建缓存
- 使用 `.dockerignore`

### 性能优化

#### 1. 启用 Gzip 压缩

已在 `nginx.conf` 中配置。

#### 2. 静态资源缓存

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

#### 3. 使用 CDN

将静态资源（图片、视频）托管到 CDN。

### 安全建议

1. **使用 HTTPS**: 生产环境必须启用 HTTPS
2. **安全头**: 已在 Nginx 配置中添加安全头
3. **限制访问**: 使用防火墙限制端口访问
4. **定期更新**: 定期更新基础镜像

## 🔗 相关文档

- [快速开始指南](./QUICKSTART.md) - 快速入门和开发环境搭建
- [Zeabur 部署指南](./ZEABUR_DEPLOYMENT.md) - Zeabur 平台部署说明（包含 Supabase 配置）
- [Supabase 集成指南](./SUPABASE_SETUP.md) - Supabase 详细配置和集成说明
- [后端开发文档](./backend/DEVELOPMENT.md)
- [前端开发文档](./frontend/DEVELOPMENT.md)
- [API接口设计文档](./docs/03-api-database/API接口设计文档.md)
- [数据库设计文档](./docs/03-api-database/数据库设计文档.md)

---

## 🌐 Supabase 集成说明

### 为什么使用 Supabase？

1. **简化部署**：无需自建 PostgreSQL 和对象存储
2. **降低成本**：免费额度适合开发和小型项目
3. **高可用性**：自动备份、99.9% 可用性
4. **易于管理**：Web 界面管理数据库和存储
5. **CDN 加速**：Storage 文件自动 CDN 加速

### Supabase 配置步骤

1. **创建项目**
   - 访问 [Supabase](https://supabase.com)
   - 创建新项目（免费计划即可）

2. **获取数据库连接**
   - Dashboard → Settings → Database
   - 复制 Connection string (URI)

3. **创建 Storage Bucket**
   - Dashboard → Storage → Buckets
   - 创建 `directorai-media` bucket
   - 设置为 Public 或 Private（根据需求）

4. **配置环境变量**
   - 在部署平台配置 `DATABASE_URL`、`SUPABASE_URL`、`SUPABASE_KEY`

5. **运行数据库迁移**
   - 使用 Supabase SQL Editor 或 psql 执行迁移脚本

详细步骤请查看 [Zeabur 部署指南](./ZEABUR_DEPLOYMENT.md)。
