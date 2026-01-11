# Data Service

AI漫导数据服务，提供用户数据管理功能。

## 功能

- **用户数据管理**
  - 获取用户详细信息
  - 更新用户信息（用户名、头像）
  - 获取用户统计数据

## 启动服务

```bash
# 1. 进入服务目录
cd backend/services/data_service

# 2. 安装依赖
pip install -r requirements.txt

# 3. 启动服务
python src/main.py

# 或使用 uvicorn
uvicorn src.main:app --reload --port 8003
```

## API 文档

启动服务后，访问：
- Swagger UI: http://localhost:8003/docs
- ReDoc: http://localhost:8003/redoc

## API 端点

### 用户数据

- `GET /api/v1/users/{user_id}` - 获取用户信息
- `PUT /api/v1/users/{user_id}` - 更新用户信息
- `GET /api/v1/users/{user_id}/stats` - 获取用户统计

## 环境变量

需要在环境变量或 `.env` 文件中配置：

```bash
DATABASE_URL=postgresql://user:password@localhost:5432/directorai
SECRET_KEY=your-secret-key
```
