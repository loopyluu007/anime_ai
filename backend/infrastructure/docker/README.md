# Docker 部署配置

本目录包含 AI漫导后端服务的 Docker 部署配置文件。

## 📋 文件说明

- `docker-compose.yml` - 生产环境配置（包含所有服务）
- `docker-compose.dev.yml` - 开发环境配置（仅基础设施：数据库、Redis、MinIO）
- `start.sh` / `start.bat` - 启动脚本
- `stop.sh` / `stop.bat` - 停止脚本

## 🚀 快速开始

### 1. 环境准备

确保已安装：
- Docker >= 20.10
- Docker Compose >= 2.0

### 2. 配置环境变量

```bash
# 复制环境变量示例文件
cd backend
cp .env.example .env

# 编辑 .env 文件，配置必要的环境变量
# 至少需要配置：
# - GLM_API_KEY
# - TUZI_API_KEY
# - GEMINI_API_KEY
# - SECRET_KEY
```

### 3. 启动服务

#### 生产环境（所有服务）

```bash
# Linux/Mac
cd infrastructure/docker
./start.sh prod

# Windows
cd infrastructure\docker
start.bat prod
```

#### 开发环境（仅基础设施）

```bash
# Linux/Mac
cd infrastructure/docker
./start.sh dev

# Windows
cd infrastructure\docker
start.bat dev
```

### 4. 停止服务

```bash
# Linux/Mac
./stop.sh [dev|prod]

# Windows
stop.bat [dev|prod]
```

## 📦 服务说明

### 生产环境服务

| 服务 | 端口 | 说明 |
|------|------|------|
| API Gateway | 8000 | 统一API入口 |
| Agent Service | 8001 | Agent业务服务 |
| Media Service | 8002 | 媒体服务（图片/视频生成） |
| Data Service | 8003 | 数据服务（用户数据/分析） |
| PostgreSQL | 5432 | 数据库 |
| Redis | 6379 | 缓存 |
| MinIO | 9000 | 对象存储 |
| MinIO Console | 9001 | MinIO管理界面 |

### 开发环境服务

开发环境只启动基础设施服务（PostgreSQL、Redis、MinIO），业务服务需要在本地运行。

## 🔧 常用命令

### 查看服务状态

```bash
# 生产环境
docker-compose ps

# 开发环境
docker-compose -f docker-compose.dev.yml ps
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f api_gateway
docker-compose logs -f agent_service
```

### 重启服务

```bash
# 重启所有服务
docker-compose restart

# 重启特定服务
docker-compose restart api_gateway
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
```

## 🐛 故障排查

### 服务无法启动

1. 检查端口是否被占用
2. 检查环境变量配置是否正确
3. 查看服务日志：`docker-compose logs [service_name]`

### 数据库连接失败

1. 检查PostgreSQL是否正常启动：`docker-compose ps postgres`
2. 检查数据库连接字符串是否正确
3. 查看PostgreSQL日志：`docker-compose logs postgres`

### 服务间通信失败

1. 确保所有服务在同一网络（`directorai_network`）
2. 检查服务依赖关系（depends_on）
3. 使用服务名而非localhost进行服务间通信

## 📝 注意事项

1. **生产环境配置**：
   - 修改默认密码（PostgreSQL、Redis、MinIO）
   - 使用强密钥（SECRET_KEY）
   - 配置正确的CORS域名
   - 启用HTTPS

2. **数据安全**：
   - 定期备份数据库
   - 保护API密钥
   - 使用环境变量而非硬编码

3. **性能优化**：
   - 根据实际负载调整资源限制
   - 配置适当的健康检查间隔
   - 使用生产级数据库配置

## 🔗 相关文档

- [后端开发文档](../../DEVELOPMENT.md)
- [API接口设计文档](../../../docs/API接口设计文档.md)
- [数据库设计文档](../../../docs/数据库设计文档.md)
