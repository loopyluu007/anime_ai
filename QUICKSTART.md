# 🚀 AI漫导 快速开始指南

> **目标**: 帮助新开发者快速搭建开发环境并启动项目  
> **版本**: v2.0  
> **最后更新**: 2026-01-15  
> **维护者**: 开发团队

---

## 📋 目录

1. [前置要求](#前置要求)
2. [快速启动（Docker方式）](#快速启动docker方式)
3. [前端 Docker 部署](#前端-docker-部署)
4. [手动启动（开发环境）](#手动启动开发环境)
5. [验证安装](#验证安装)
6. [常见问题](#常见问题)
7. [下一步](#下一步)

---

## 📦 前置要求

### 必需软件

| 软件 | 版本要求 | 说明 |
|------|---------|------|
| **Python** | >= 3.11 | 后端开发 |
| **Flutter** | >= 3.0.0 | 前端开发 |
| **Docker** | >= 20.10 | 容器化部署（推荐） |
| **Docker Compose** | >= 2.0 | 容器编排 |
| **PostgreSQL** | >= 15 | 数据库（手动启动时需要） |
| **Redis** | >= 7 | 缓存（手动启动时需要） |

### 可选软件

- **Node.js** >= 18（用于某些构建工具）
- **Git**（版本控制）
- **VS Code** 或 **Android Studio**（开发工具）

---

## 🐳 快速启动（Docker方式 - 推荐）

> **推荐方式**：使用项目根目录的统一部署脚本，一键启动前后端所有服务，无需手动配置环境。

### 1. 克隆项目

```bash
git clone <repository-url>
cd anime_ai
```

### 2. 配置环境变量

```bash
# 在项目根目录
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，配置必要的API密钥
# 至少需要配置以下密钥：
# - GLM_API_KEY=your-glm-api-key
# - TUZI_API_KEY=your-tuzi-api-key
# - GEMINI_API_KEY=your-gemini-api-key
# - SECRET_KEY=your-secret-key-change-in-production
```

### 3. 启动所有服务（一键部署）

```bash
# 在项目根目录执行

# Linux/Mac
./start.sh prod

# Windows
start.bat prod
```

这将自动启动：
- ✅ 前端服务（Flutter Web）- http://localhost:8080
- ✅ 后端服务（API Gateway + 所有微服务）
- ✅ 基础设施（PostgreSQL、Redis、MinIO）

### 4. 验证服务

> ⏱️ **启动时间说明**：由于健康检查优化，应用现在有更充足的启动时间（后端服务60秒启动期）。首次启动可能需要1-3分钟，请耐心等待。

等待所有服务启动完成后（约1-3分钟），可以通过以下方式检查服务状态：

```bash
# 查看所有服务状态
docker-compose ps

# 查看服务健康状态（所有服务应显示为 healthy）
docker-compose ps --format json
```

服务启动完成后，访问：

**前端应用**:
- **Frontend**: http://localhost:8080

**后端服务**:
- **API Gateway**: http://localhost:8000/docs
- **Agent Service**: http://localhost:8001/docs
- **Media Service**: http://localhost:8002/docs
- **Data Service**: http://localhost:8003/docs

**基础设施**:
- **MinIO Console**: http://localhost:9001
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379

### 5. 停止服务

```bash
# Linux/Mac
./stop.sh

# Windows
stop.bat
```

### 6. 其他启动选项

```bash
# 只启动前端
./start.sh prod frontend    # Linux/Mac
start.bat prod frontend     # Windows

# 只启动后端
./start.sh prod backend     # Linux/Mac
start.bat prod backend      # Windows

# 开发环境（只启动基础设施：数据库、Redis、MinIO）
./start.sh dev              # Linux/Mac
start.bat dev               # Windows
```

> 📖 **详细部署说明**：查看 [部署文档](./DEPLOYMENT.md) 获取完整的部署指南，包括前端独立部署、生产环境配置、故障排查等详细内容。

---

## 🛠️ 手动启动（开发环境）

> **适合场景**：需要调试、修改代码或进行开发时使用。

### 后端服务

#### 1. 安装Python依赖

```bash
cd backend

# 创建虚拟环境
python -m venv venv

# 激活虚拟环境
# Windows:
venv\Scripts\activate
# Linux/Mac:
source venv/bin/activate

# 安装依赖
pip install -r requirements.txt

# 安装各服务的依赖
cd services/agent_service
pip install -r requirements.txt
cd ../media_service
pip install -r requirements.txt
cd ../data_service
pip install -r requirements.txt
cd ../../api_gateway
pip install -r requirements.txt
```

#### 2. 配置数据库

```bash
# 创建PostgreSQL数据库
createdb directorai

# 运行数据库迁移
psql -U postgres -d directorai -f infrastructure/database/migrations/001_initial.sql
```

#### 3. 配置环境变量

创建 `backend/.env` 文件：

```bash
# 数据库
DATABASE_URL=postgresql://user:password@localhost:5432/directorai

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# API Keys（必需）
GLM_API_KEY=your-glm-api-key
TUZI_API_KEY=your-tuzi-api-key
GEMINI_API_KEY=your-gemini-api-key
```

#### 4. 启动后端服务

**方式1：使用Docker启动基础设施（推荐）**

```bash
# 在项目根目录执行
# 仅启动PostgreSQL、Redis、MinIO
./start.sh dev  # Linux/Mac
start.bat dev   # Windows
```

然后分别启动各个服务：

```bash
# 终端1：启动Agent Service
cd backend/services/agent_service
uvicorn src.main:app --reload --port 8001

# 终端2：启动Media Service
cd backend/services/media_service
uvicorn src.main:app --reload --port 8002

# 终端3：启动Data Service
cd backend/services/data_service
uvicorn src.main:app --reload --port 8003

# 终端4：启动API Gateway
cd backend/api_gateway
uvicorn src.main:app --reload --port 8000
```

**方式2：手动启动所有服务**

确保PostgreSQL和Redis已启动，然后按照方式1的步骤启动各个服务。

### 前端应用

#### 1. 安装Flutter依赖

```bash
# 返回项目根目录
cd ../..

# 安装依赖
flutter pub get

# 生成代码（如果需要）
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 2. 配置API地址

编辑 `lib/core/config/api_config.dart`（或使用环境变量）：

```dart
class ApiConfig {
  // 如果使用API Gateway（推荐）
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String wsUrl = 'ws://localhost:8000/ws';
  
  // 或直接连接Agent Service
  // static const String baseUrl = 'http://localhost:8001/api/v1';
  // static const String wsUrl = 'ws://localhost:8001/ws';
}
```

#### 3. 启动应用

```bash
# Web端
flutter run -d chrome

# Android（需要设备或模拟器）
flutter run -d android

# iOS（需要Mac和设备/模拟器）
flutter run -d ios
```

---

## ✅ 验证安装

### 1. 检查后端服务

访问以下URL，应该能看到Swagger API文档：

- http://localhost:8000/docs（API Gateway）
- http://localhost:8001/docs（Agent Service）
- http://localhost:8002/docs（Media Service）
- http://localhost:8003/docs（Data Service）

### 2. 测试API

使用Swagger UI或curl测试API：

```bash
# 注册用户
curl -X POST "http://localhost:8000/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "test123456"
  }'

# 登录获取Token
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "test123456"
  }'
```

### 3. 检查前端

- 打开浏览器访问应用
- 尝试注册/登录
- 检查控制台是否有错误

---

## ❓ 常见问题

### 1. Docker启动失败

**问题**: `docker-compose up` 失败

**解决方案**:
- 检查Docker和Docker Compose是否已安装并运行
- 检查端口是否被占用（8000, 8001, 8002, 8003, 5432, 6379）
- 查看Docker日志：`docker-compose logs -f [service_name]`
- 检查服务健康状态：`docker-compose ps`（查看健康检查状态）

### 1.1 服务启动时间过长或健康检查失败

**问题**: 服务启动时间超过预期，或健康检查失败导致容器重启

**说明**: 
- 项目已优化健康检查配置，后端服务有60秒启动期，前端有20秒启动期
- 首次启动可能需要更长时间（数据库初始化、依赖安装等）
- 如果启动时间超过3分钟，建议查看服务日志排查问题

**解决方案**:
- 查看服务日志：`docker-compose logs -f [service_name]`
- 检查服务状态：`docker-compose ps`（确认健康检查状态）
- 如果启动时间超过预期，查看日志确认是否有错误
- 确认资源充足（CPU、内存），资源不足可能导致启动慢
- 参考 [健康检查优化方案](./docs/健康检查优化方案.md) 了解更多信息

### 2. 数据库连接失败

**问题**: `sqlalchemy.exc.OperationalError`

**解决方案**:
- 检查PostgreSQL是否运行：`pg_isready`
- 检查 `DATABASE_URL` 配置是否正确
- 确认数据库用户权限
- 检查防火墙设置

### 3. Redis连接失败

**问题**: `redis.exceptions.ConnectionError`

**解决方案**:
- 检查Redis是否运行：`redis-cli ping`
- 检查 `REDIS_URL` 配置
- 确认Redis服务可访问

### 4. API密钥错误

**问题**: 第三方API调用失败（GLM、Tuzi、Gemini）

**解决方案**:
- 检查 `.env` 文件中的API密钥是否正确
- 确认API密钥是否有效（访问对应服务商的控制台）
- 检查API密钥的权限和配额

### 5. Flutter依赖安装失败

**问题**: `flutter pub get` 失败

**解决方案**:
- 检查网络连接
- 清理缓存：`flutter pub cache clean`
- 更新Flutter：`flutter upgrade`
- 检查 `pubspec.yaml` 语法

### 6. 端口被占用

**问题**: `Address already in use`

**解决方案**:
- 查找占用端口的进程并关闭
- Windows: `netstat -ano | findstr :8000`
- Linux/Mac: `lsof -i :8000`
- 或修改服务端口配置

---

## 📚 下一步

### 了解项目架构

- 📖 [架构设计总览](./docs/01-architecture/架构设计总览.md)
- 📖 [项目结构规划](./docs/01-architecture/项目结构规划.md)

### 开始开发

- 🔧 [后端开发指南](./backend/DEVELOPMENT.md)
- 🔧 [前端开发指南](./frontend/DEVELOPMENT.md)
- 🔧 [工程实施索引](./docs/02-implementation/工程实施索引.md)

### 查看API文档

- 🔌 [API接口设计文档](./docs/03-api-database/API接口设计文档.md)
- 🔌 [数据库设计文档](./docs/03-api-database/数据库设计文档.md)

### 了解业务逻辑

- 💼 [视频生成完整流程](./docs/04-business/视频生成完整流程.md)
- 💼 [人物一致性解决方案](./docs/04-business/人物一致性解决方案.md)

### AI Agent开发

- 🤖 [AI_Agent开发指南](./docs/AI_Agent开发指南.md)

---

## 📝 快速命令参考

### 统一部署脚本（推荐）

```bash
# 在项目根目录执行

# 启动所有服务（生产环境）
./start.sh prod        # Linux/Mac
start.bat prod         # Windows

# 启动特定组件
./start.sh prod frontend    # 只启动前端
./start.sh prod backend     # 只启动后端
./start.sh prod all         # 启动所有（默认）

# 启动基础设施（开发环境）
./start.sh dev              # Linux/Mac
start.bat dev               # Windows

# 停止服务
./stop.sh                   # 停止所有服务
./stop.sh frontend          # 只停止前端
./stop.sh backend           # 只停止后端
stop.bat                    # Windows

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f                    # 所有服务
docker-compose logs -f frontend           # 前端
docker-compose logs -f api_gateway        # API网关
docker-compose logs -f agent_service      # Agent服务

# 查看服务健康状态
docker-compose ps                         # 查看所有服务状态和健康检查
docker-compose ps --format json           # JSON格式输出（便于脚本处理）

# 重新构建并启动
docker-compose up -d --build

# 重启服务
docker-compose restart [service_name]
```

> 📖 **更多命令**：查看 [部署文档](./DEPLOYMENT.md) 获取完整的命令参考和详细说明。

### 后端命令

```bash
# 激活虚拟环境
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# 启动服务
uvicorn src.main:app --reload --port 8001

# 运行测试
pytest

# 数据库迁移
psql -U postgres -d directorai -f infrastructure/database/migrations/001_initial.sql
```

### 前端命令

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run -d chrome      # Web
flutter run -d android    # Android
flutter run -d ios        # iOS

# 构建应用
flutter build web         # Web
flutter build apk         # Android APK
flutter build ios         # iOS

# 代码分析
flutter analyze
dart format lib/
```

---

## 🎯 开发环境检查清单

在开始开发前，请确认：

- [ ] Python 3.11+ 已安装（手动启动时需要）
- [ ] Flutter 3.0+ 已安装（手动启动时需要）
- [ ] Docker 和 Docker Compose 已安装（推荐使用Docker方式）
- [ ] PostgreSQL 和 Redis 已安装（仅手动启动时需要）
- [ ] 已配置所有必需的API密钥（GLM、Tuzi、Gemini）
- [ ] 已在项目根目录创建并配置 `.env` 文件
- [ ] 已运行统一部署脚本 `./start.sh prod` 或 `start.bat prod`
- [ ] 所有服务可以正常启动（首次启动可能需要1-3分钟）
- [ ] 所有服务健康检查通过（使用 `docker-compose ps` 检查）
- [ ] 可以访问前端应用：http://localhost:8080
- [ ] 可以访问API文档（Swagger UI）：http://localhost:8000/docs

---

## 📚 相关文档

### 部署相关

- 📖 [统一部署指南](./DEPLOYMENT.md) - 完整的部署文档，包括生产环境配置、故障排查等
- 📖 [后端开发文档](./backend/DEVELOPMENT.md) - 后端开发指南
- 📖 [前端开发文档](./frontend/DEVELOPMENT.md) - 前端开发指南
- 📖 [健康检查优化方案](./docs/健康检查优化方案.md) - 健康检查优化说明
- 📖 [健康检查优化总结](./docs/健康检查优化总结.md) - 优化效果和使用建议

### 外部资源

- [Flutter Web 部署文档](https://docs.flutter.dev/deployment/web)
- [Nginx 官方文档](https://nginx.org/en/docs/)
- [Docker 官方文档](https://docs.docker.com/)

---

**文档版本**: v2.1  
**最后更新**: 2026-01-16  
**维护者**: 开发团队
