"""
Media Service 主入口
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from services.media_service.src.api import images, videos
from shared.middleware.error_handler import error_handler_middleware

app = FastAPI(
    title="AI漫导 Media Service",
    description="媒体服务API（图片生成、视频生成）",
    version="1.0.0"
)

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境应配置具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 错误处理中间件（必须在最后注册）
@app.middleware("http")
async def error_handler(request, call_next):
    return await error_handler_middleware(request, call_next)

# 注册路由
app.include_router(images.router, prefix="/api/v1")
app.include_router(videos.router, prefix="/api/v1")

@app.get("/")
async def root():
    """根路径"""
    return {"message": "AI漫导 Media Service", "version": "1.0.0"}

@app.get("/health")
async def health():
    """健康检查"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8002)
