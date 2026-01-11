"""
Agent Service 主入口
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from services.agent_service.src.api import auth, conversations, tasks, screenplays, messages
from services.agent_service.src.api.websocket import websocket_endpoint

app = FastAPI(
    title="AI漫导 Agent Service",
    description="Agent 业务服务API",
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

# 注册路由
app.include_router(auth.router, prefix="/api/v1")
app.include_router(conversations.router, prefix="/api/v1")
app.include_router(tasks.router, prefix="/api/v1")
app.include_router(screenplays.router, prefix="/api/v1")
app.include_router(messages.router, prefix="/api/v1")

# 注册WebSocket路由
@app.websocket("/ws")
async def websocket_route(websocket):
    """WebSocket 路由"""
    await websocket_endpoint(websocket)

@app.get("/")
async def root():
    """根路径"""
    return {"message": "AI漫导 Agent Service", "version": "1.0.0"}

@app.get("/health")
async def health():
    """健康检查"""
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
