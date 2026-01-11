# AI漫导 后端服务

> **技术栈**: Python FastAPI + PostgreSQL + Redis

## 项目结构

```
backend/
├── api_gateway/          # API 网关服务
├── services/             # 业务服务
│   ├── agent_service/    # Agent 业务服务
│   ├── media_service/    # 媒体服务
│   └── data_service/     # 数据服务
├── shared/               # 共享模块
├── infrastructure/       # 基础设施
└── tests/                # 测试
```

## 环境要求

- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose (可选)

## 快速开始

### 1. 安装依赖

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，配置数据库和 API Key
```

### 3. 初始化数据库

```bash
# 运行数据库迁移脚本
psql -U postgres -d directorai -f infrastructure/database/migrations/001_initial.sql
```

### 4. 启动服务

```bash
# 启动 Agent Service
cd services/agent_service
uvicorn src.main:app --reload --port 8001

# 启动 Media Service
cd services/media_service
uvicorn src.main:app --reload --port 8002
```

## 开发

详细文档请参考 [docs/后端工程实施方案.md](../docs/后端工程实施方案.md)
