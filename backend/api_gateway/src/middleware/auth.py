"""
JWT 认证中间件
"""
from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from typing import Optional
import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from api_gateway.src.config.settings import settings


security = HTTPBearer(auto_error=False)


async def verify_token(token: str) -> Optional[dict]:
    """
    验证 JWT Token
    
    Args:
        token: JWT Token 字符串
        
    Returns:
        解码后的 payload，如果无效则返回 None
    """
    try:
        payload = jwt.decode(
            token, 
            settings.SECRET_KEY, 
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except JWTError:
        return None


async def get_current_user(request: Request) -> Optional[dict]:
    """
    从请求中获取当前用户信息
    
    Args:
        request: FastAPI 请求对象
        
    Returns:
        用户信息字典，如果未认证则返回 None
    """
    # 从 Header 中获取 Token
    authorization: str = request.headers.get("Authorization", "")
    if not authorization.startswith("Bearer "):
        return None
    
    token = authorization.replace("Bearer ", "").strip()
    if not token:
        return None
    
    payload = await verify_token(token)
    
    if payload is None:
        return None
    
    return {
        "user_id": payload.get("sub"),
        "username": payload.get("username"),
        "email": payload.get("email"),
    }


async def auth_middleware(request: Request, call_next):
    """
    认证中间件
    
    对需要认证的路径进行 Token 验证
    """
    # 检查是否是公开路径
    if any(request.url.path.startswith(path) for path in settings.PUBLIC_PATHS):
        response = await call_next(request)
        return response
    
    # 验证 Token
    user = await get_current_user(request)
    if user is None:
        # 对于需要认证的路径，如果没有有效 Token，返回 401
        return HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="未授权，请先登录",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # 将用户信息添加到请求状态中
    request.state.user = user
    
    response = await call_next(request)
    return response
