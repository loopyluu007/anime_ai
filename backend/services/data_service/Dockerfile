# Data Service Dockerfile
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
COPY backend/services/data_service/requirements.txt /app/requirements.txt

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 复制项目代码
COPY backend/services/data_service/ /app/services/data_service/
COPY backend/shared/ /app/shared/

# 设置Python路径
ENV PYTHONPATH=/app

# 暴露端口
EXPOSE 8003

# 健康检查（优化：增加启动期到60秒，增加重试次数）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=5 \
    CMD curl -f http://localhost:8003/health || exit 1

# 启动命令
CMD ["uvicorn", "services.data_service.src.main:app", "--host", "0.0.0.0", "--port", "8003"]
