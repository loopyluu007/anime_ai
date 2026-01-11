"""
API Gateway 主入口
"""
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from api_gateway.src.config.settings import settings
from api_gateway.src.middleware.cors import setup_cors
from api_gateway.src.middleware.auth import auth_middleware
from api_gateway.src.middleware.rate_limit import rate_limit_middleware
from api_gateway.src.routes.gateway import router


app = FastAPI(
    title="AI漫导 API Gateway",
    description="统一API入口，提供认证、限流、路由转发等功能",
    version="1.0.0"
)

# 配置 CORS
setup_cors(app)

# 注册中间件（注意顺序：先限流，后认证）
@app.middleware("http")
async def rate_limit_middleware_wrapper(request: Request, call_next):
    """限流中间件包装器"""
    from api_gateway.src.middleware.rate_limit import rate_limit_middleware
    return await rate_limit_middleware(request, call_next)


@app.middleware("http")
async def auth_middleware_wrapper(request: Request, call_next):
    """认证中间件包装器"""
    # 检查是否是公开路径
    if any(request.url.path.startswith(path) for path in settings.PUBLIC_PATHS):
        response = await call_next(request)
        return response
    
    # 验证 Token
    from api_gateway.src.middleware.auth import get_current_user
    user = await get_current_user(request)
    
    if user is None:
        # 对于需要认证的路径，如果没有有效 Token，返回 401
        return JSONResponse(
            status_code=401,
            content={"detail": "未授权，请先登录"},
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 将用户信息添加到请求状态中
    request.state.user = user
    
    response = await call_next(request)
    return response


# 注册路由
app.include_router(router)


@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "AI漫导 API Gateway",
        "version": "1.0.0",
        "services": {
            "agent_service": settings.AGENT_SERVICE_URL,
            "media_service": settings.MEDIA_SERVICE_URL,
            "data_service": settings.DATA_SERVICE_URL,
        }
    }


@app.get("/health")
async def health():
    """健康检查"""
    return {"status": "healthy", "service": "api_gateway"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
