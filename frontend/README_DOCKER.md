# 前端 Docker 部署指南

本文档介绍如何使用 Docker 构建和部署 Flutter Web 前端应用。

## 📋 目录

1. [快速开始](#快速开始)
2. [构建镜像](#构建镜像)
3. [运行容器](#运行容器)
4. [Docker Compose](#docker-compose)
5. [生产环境部署](#生产环境部署)
6. [常见问题](#常见问题)

---

## 🚀 快速开始

### 前置要求

- Docker 20.10+
- Docker Compose 2.0+（可选）

### 快速启动

```bash
# 使用 Docker Compose（推荐）
cd frontend
docker-compose up -d

# 或使用 Docker 命令
docker build -t director-ai-frontend -f frontend/Dockerfile .
docker run -d -p 8080:80 --name director-ai-frontend director-ai-frontend
```

访问: http://localhost:8080

---

## 🔨 构建镜像

### 基本构建

```bash
# 在项目根目录执行
docker build -t director-ai-frontend -f frontend/Dockerfile .
```

### 构建参数

```bash
# 指定 Flutter 版本
docker build \
  --build-arg FLUTTER_VERSION=stable \
  -t director-ai-frontend \
  -f frontend/Dockerfile .
```

### 多阶段构建说明

Dockerfile 使用多阶段构建：

1. **构建阶段**: 使用 Flutter SDK 构建 Web 应用
2. **运行阶段**: 使用轻量级 Nginx 提供静态文件

优势：
- 最终镜像体积小（~50MB）
- 构建和运行环境分离
- 安全性更高

---

## 🐳 运行容器

### 基本运行

```bash
docker run -d \
  -p 8080:80 \
  --name director-ai-frontend \
  director-ai-frontend
```

### 自定义端口

```bash
docker run -d \
  -p 3000:80 \
  --name director-ai-frontend \
  director-ai-frontend
```

### 挂载自定义配置

```bash
docker run -d \
  -p 8080:80 \
  -v $(pwd)/frontend/nginx.conf:/etc/nginx/conf.d/default.conf \
  --name director-ai-frontend \
  director-ai-frontend
```

---

## 🎯 Docker Compose

### 使用 Docker Compose（推荐）

```bash
cd frontend
docker-compose up -d
```

### 查看日志

```bash
docker-compose logs -f frontend
```

### 停止服务

```bash
docker-compose down
```

### 重新构建

```bash
docker-compose up -d --build
```

---

## 🏭 生产环境部署

### 1. 使用 HTTPS

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

### 2. 环境变量配置

创建 `.env` 文件：

```env
API_BASE_URL=https://api.your-domain.com/api/v1
WS_URL=wss://api.your-domain.com/ws
```

### 3. 生产环境 Docker Compose

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

### 4. 使用反向代理（推荐）

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

---

## 🔧 自定义配置

### 修改 Nginx 配置

1. 编辑 `frontend/nginx.conf`
2. 重新构建镜像或挂载配置文件

```bash
docker run -d \
  -p 8080:80 \
  -v $(pwd)/frontend/nginx.conf:/etc/nginx/conf.d/default.conf \
  director-ai-frontend
```

### 添加环境变量

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

---

## ❓ 常见问题

### 1. 构建失败 - Flutter 版本不兼容

**问题**: `flutter build web` 失败

**解决**:
```bash
# 检查 Flutter 版本
docker run --rm ghcr.io/cirruslabs/flutter:stable flutter --version

# 使用特定版本
FROM ghcr.io/cirruslabs/flutter:3.16.0 AS build
```

### 2. 路由 404 错误

**问题**: 刷新页面后出现 404

**解决**: 确保 Nginx 配置包含：
```nginx
location / {
    try_files $uri $uri/ /index.html;
}
```

### 3. API 请求跨域错误

**问题**: CORS 错误

**解决**: 
- 在后端配置 CORS
- 或使用 Nginx 反向代理

### 4. 静态资源加载失败

**问题**: CSS/JS 文件 404

**解决**: 检查构建输出路径：
```bash
# 确认构建产物位置
docker run --rm director-ai-frontend ls -la /usr/share/nginx/html
```

### 5. 镜像体积过大

**问题**: 镜像超过 1GB

**解决**: 
- 使用多阶段构建（已实现）
- 清理构建缓存
- 使用 `.dockerignore`

---

## 📊 性能优化

### 1. 启用 Gzip 压缩

已在 `nginx.conf` 中配置。

### 2. 静态资源缓存

```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 3. 使用 CDN

将静态资源（图片、视频）托管到 CDN。

---

## 🔐 安全建议

1. **使用 HTTPS**: 生产环境必须启用 HTTPS
2. **安全头**: 已在 Nginx 配置中添加安全头
3. **限制访问**: 使用防火墙限制端口访问
4. **定期更新**: 定期更新基础镜像

---

## 📚 相关文档

- [Flutter Web 部署文档](https://docs.flutter.dev/deployment/web)
- [Nginx 官方文档](https://nginx.org/en/docs/)
- [Docker 官方文档](https://docs.docker.com/)

---

**最后更新**: 2026-01-11
