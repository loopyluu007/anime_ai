# AI漫导统一部署指南

本文档说明如何使用项目根目录的统一部署脚本进行前后端一体化部署。

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

### 1. 环境准备

确保已安装：
- Docker >= 20.10
- Docker Compose >= 2.0（或 docker-compose >= 1.29）

### 2. 配置环境变量

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑 .env 文件，配置必要的环境变量
# 至少需要配置：
# - GLM_API_KEY
# - TUZI_API_KEY
# - GEMINI_API_KEY
# - SECRET_KEY
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

### 必需配置

- `GLM_API_KEY` - 智谱 AI API 密钥（用于对话和剧本生成）
- `TUZI_API_KEY` - 图子 API 密钥（用于视频生成）
- `GEMINI_API_KEY` - Google Gemini API 密钥（用于图片生成）
- `SECRET_KEY` - JWT 密钥（生产环境请使用强密钥）

### 可选配置

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

## 🔗 相关文档

- [后端开发文档](backend/DEVELOPMENT.md)
- [前端开发文档](frontend/DEVELOPMENT.md)
- [API接口设计文档](docs/03-api-database/API接口设计文档.md)
- [数据库设计文档](docs/03-api-database/数据库设计文档.md)
