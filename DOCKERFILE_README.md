# Dockerfile 说明文档

> **最后更新**: 2026-01-16

---

## 📋 Dockerfile 文件列表

### 后端服务 Dockerfile

#### Zeabur 部署专用（推荐用于云平台）

| 服务 | Dockerfile 路径 | 端口 | 说明 |
|------|----------------|------|------|
| **API Gateway** | `backend/api_gateway/Dockerfile.zeabur` | 8000 | 统一 API 入口 |
| **Agent Service** | `backend/services/agent_service/Dockerfile.zeabur` | 8001 | 业务服务 |
| **Media Service** | `backend/services/media_service/Dockerfile.zeabur` | 8002 | 媒体服务（支持 Supabase Storage） |
| **Data Service** | `backend/services/data_service/Dockerfile.zeabur` | 8003 | 数据服务 |

#### 通用 Dockerfile（用于本地开发或 Docker Compose）

| 服务 | Dockerfile 路径 | 端口 | 说明 |
|------|----------------|------|------|
| **API Gateway** | `backend/api_gateway/Dockerfile` | 8000 | 统一 API 入口 |
| **Agent Service** | `backend/services/agent_service/Dockerfile` | 8001 | 业务服务 |
| **Media Service** | `backend/services/media_service/Dockerfile` | 8002 | 媒体服务 |
| **Data Service** | `backend/services/data_service/Dockerfile` | 8003 | 数据服务 |

### 前端 Dockerfile

| 组件 | Dockerfile 路径 | 端口 | 说明 |
|------|----------------|------|------|
| **Frontend** | `frontend/Dockerfile` | 80 | Flutter Web 应用 |

### 根目录 Dockerfile

| 文件 | 说明 |
|------|------|
| `Dockerfile.zeabur` | 已迁移到 `backend/api_gateway/Dockerfile.zeabur`，保留用于向后兼容 |

---

## 🚀 使用说明

### Zeabur 部署

在 Zeabur 平台上部署时，使用 `Dockerfile.zeabur` 文件：

1. **API Gateway**
   - Dockerfile 路径: `backend/api_gateway/Dockerfile.zeabur`
   - 端口: `8000`

2. **Agent Service**
   - Dockerfile 路径: `backend/services/agent_service/Dockerfile.zeabur`
   - 端口: `8001`

3. **Media Service**
   - Dockerfile 路径: `backend/services/media_service/Dockerfile.zeabur`
   - 端口: `8002`

4. **Data Service**
   - Dockerfile 路径: `backend/services/data_service/Dockerfile.zeabur`
   - 端口: `8003`

详细部署步骤请查看 [完整部署指南](./DEPLOYMENT_GUIDE.md)

### 本地 Docker Compose 部署

使用通用 Dockerfile（不带 `.zeabur` 后缀）：

```bash
# 使用 docker-compose.yml
docker-compose up -d
```

详细步骤请查看 [本地部署指南](./DEPLOYMENT.md)

---

## 🔧 Dockerfile 特点

### 后端服务 Dockerfile

- ✅ 基于 Python 3.11-slim 镜像
- ✅ 多阶段构建优化（可选）
- ✅ 健康检查配置
- ✅ 环境变量优化
- ✅ 最小化镜像体积

### 前端 Dockerfile

- ✅ 多阶段构建（Flutter 构建 + Nginx 运行）
- ✅ 自动启用 Web 支持
- ✅ SPA 路由支持
- ✅ Gzip 压缩
- ✅ 静态资源缓存

---

## 📝 构建参数

### 后端服务

所有后端服务 Dockerfile 支持以下环境变量：

```env
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
PIP_NO_CACHE_DIR=1
PYTHONPATH=/app
```

### 前端

前端 Dockerfile 支持以下构建参数：

```bash
# 指定 Flutter 版本（可选）
--build-arg FLUTTER_VERSION=stable
```

---

## 🐛 常见问题

### 1. 构建失败 - 找不到文件

**问题**: `COPY backend/...` 失败

**解决**: 确保在项目根目录执行构建命令

```bash
# 正确：在项目根目录
docker build -f backend/api_gateway/Dockerfile.zeabur .

# 错误：在 backend 目录
cd backend
docker build -f api_gateway/Dockerfile.zeabur .  # ❌
```

### 2. 端口冲突

**问题**: 端口已被占用

**解决**: 
- 修改 Dockerfile 中的 `EXPOSE` 端口
- 或使用 `-p` 参数映射到其他端口

### 3. 健康检查失败

**问题**: 健康检查超时

**解决**:
- 检查服务是否正常启动
- 增加 `--start-period` 时间
- 确认健康检查端点存在

---

## 🔗 相关文档

- [完整部署指南](./DEPLOYMENT_GUIDE.md) - 云平台部署
- [本地部署指南](./DEPLOYMENT.md) - Docker Compose 部署
- [后端开发文档](./backend/DEVELOPMENT.md) - 后端开发指南

---

**维护者**: 开发团队
