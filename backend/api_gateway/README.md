# API Gateway

> **版本**: v1.0  
> **端口**: 8000  
> **功能**: 统一API入口，提供认证、限流、路由转发等功能

---

## 📋 功能特性

- ✅ **统一入口**: 所有API请求通过网关统一处理
- ✅ **JWT认证**: 统一验证用户Token（除公开路径外）
- ✅ **限流保护**: 基于IP和用户ID的请求限流
- ✅ **CORS支持**: 跨域请求支持
- ✅ **路由转发**: 自动转发请求到对应的后端服务
- ✅ **健康检查**: 网关和服务健康状态监控

---

## 🚀 快速开始

### 1. 安装依赖

```bash
cd backend/api_gateway
pip install -r requirements.txt
```

### 2. 配置环境变量

创建 `.env` 文件（或设置系统环境变量）：

```bash
# 服务地址配置
AGENT_SERVICE_URL=http://localhost:8001
MEDIA_SERVICE_URL=http://localhost:8002
DATA_SERVICE_URL=http://localhost:8003

# JWT 配置（需要与 Agent Service 保持一致）
SECRET_KEY=your-secret-key-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# 限流配置
RATE_LIMIT_ENABLED=true
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=60

# CORS 配置
CORS_ORIGINS=*
CORS_CREDENTIALS=true
CORS_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_HEADERS=*
```

### 3. 启动服务

```bash
# 方式1: 使用 uvicorn
uvicorn src.main:app --reload --port 8000

# 方式2: 直接运行
python src/main.py
```

### 4. 访问服务

- **API文档**: http://localhost:8000/docs
- **健康检查**: http://localhost:8000/health
- **API入口**: http://localhost:8000/api/v1

---

## 📁 项目结构

```
api_gateway/
├── src/
│   ├── __init__.py
│   ├── main.py              # 主入口文件
│   ├── config/              # 配置模块
│   │   ├── __init__.py
│   │   └── settings.py      # 配置管理
│   ├── middleware/          # 中间件
│   │   ├── __init__.py
│   │   ├── auth.py          # JWT认证中间件
│   │   ├── rate_limit.py    # 限流中间件
│   │   └── cors.py          # CORS中间件
│   └── routes/              # 路由
│       ├── __init__.py
│       └── gateway.py       # 网关路由转发
├── requirements.txt
└── README.md
```

---

## 🔧 配置说明

### 服务路由映射

网关根据路径前缀自动转发到对应的服务：

| 路径前缀 | 目标服务 | 说明 |
|---------|---------|------|
| `/api/v1/auth` | Agent Service | 认证相关 |
| `/api/v1/conversations` | Agent Service | 对话管理 |
| `/api/v1/tasks` | Agent Service | 任务管理 |
| `/api/v1/screenplays` | Agent Service | 剧本管理 |
| `/api/v1/images` | Media Service | 图片生成 |
| `/api/v1/videos` | Media Service | 视频生成 |
| `/api/v1/users` | Data Service | 用户管理 |

### 公开路径（无需认证）

以下路径不需要JWT认证：

- `/health` - 健康检查
- `/docs` - API文档
- `/redoc` - ReDoc文档
- `/openapi.json` - OpenAPI规范
- `/api/v1/auth/login` - 用户登录
- `/api/v1/auth/register` - 用户注册

---

## 🔐 认证流程

1. 客户端请求需要认证的API时，需要在Header中携带Token：
   ```
   Authorization: Bearer {token}
   ```

2. 网关验证Token的有效性：
   - Token有效：转发请求到目标服务，并在Header中添加用户信息
   - Token无效：返回401未授权错误

3. 目标服务可以通过以下Header获取用户信息：
   - `X-User-ID`: 用户ID
   - `X-Username`: 用户名

---

## ⚡ 限流机制

### 限流规则

- **限流键**: 优先使用用户ID，否则使用IP地址
- **默认限制**: 100次请求/60秒
- **响应头**: 返回限流信息
  - `X-RateLimit-Limit`: 限制数量
  - `X-RateLimit-Remaining`: 剩余请求数
  - `X-RateLimit-Reset`: 重置时间戳

### 限流响应

当超过限流时，返回429状态码：

```json
{
  "detail": "请求过于频繁，请稍后再试。限制：100 次/60秒"
}
```

---

## 🏥 健康检查

### 网关健康检查

```bash
GET /health
```

响应示例：

```json
{
  "status": "healthy",
  "gateway": "running",
  "services": {
    "agent_service": {
      "status": "healthy",
      "url": "http://localhost:8001"
    },
    "media_service": {
      "status": "healthy",
      "url": "http://localhost:8002"
    },
    "data_service": {
      "status": "healthy",
      "url": "http://localhost:8003"
    }
  }
}
```

---

## 🐛 错误处理

### 常见错误码

| 状态码 | 说明 |
|--------|------|
| 401 | 未授权（Token无效或缺失） |
| 404 | 未找到对应的服务路由 |
| 429 | 请求过于频繁（限流） |
| 503 | 服务不可用（目标服务无法连接） |
| 504 | 网关超时（目标服务响应超时） |

---

## 📝 开发说明

### 添加新的服务路由

在 `src/config/settings.py` 中的 `SERVICE_ROUTES` 添加新路由：

```python
SERVICE_ROUTES: Dict[str, str] = {
    # ... 现有路由
    "/api/v1/new-service": "http://localhost:8004",
}
```

### 添加新的公开路径

在 `src/config/settings.py` 中的 `PUBLIC_PATHS` 添加新路径：

```python
PUBLIC_PATHS: List[str] = [
    # ... 现有路径
    "/api/v1/public-endpoint",
]
```

---

## 🔗 相关文档

- [后端工程实施方案](../../docs/后端工程实施方案.md)
- [API接口设计文档](../../docs/API接口设计文档.md)
- [架构拆分方案](../../docs/架构拆分方案.md)

---

**文档版本**: v1.0  
**最后更新**: 2026-01-12  
**维护者**: 开发团队
