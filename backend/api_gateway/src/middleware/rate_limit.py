"""
限流中间件
"""
from fastapi import Request, HTTPException, status
from typing import Dict, Tuple
import time
from collections import defaultdict
import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from api_gateway.src.config.settings import settings


# 简单的内存限流器（生产环境应使用 Redis）
class RateLimiter:
    """限流器"""
    
    def __init__(self):
        self.requests: Dict[str, list] = defaultdict(list)
    
    def is_allowed(self, key: str, max_requests: int, window: int) -> Tuple[bool, int]:
        """
        检查是否允许请求
        
        Args:
            key: 限流键（通常是 IP 地址或用户 ID）
            max_requests: 时间窗口内最大请求数
            window: 时间窗口（秒）
            
        Returns:
            (是否允许, 剩余请求数)
        """
        if not settings.RATE_LIMIT_ENABLED:
            return True, max_requests
        
        now = time.time()
        # 清理过期记录
        self.requests[key] = [
            req_time 
            for req_time in self.requests[key] 
            if now - req_time < window
        ]
        
        # 检查是否超过限制
        if len(self.requests[key]) >= max_requests:
            remaining = 0
        else:
            self.requests[key].append(now)
            remaining = max_requests - len(self.requests[key])
        
        return len(self.requests[key]) <= max_requests, remaining


# 全局限流器实例
rate_limiter = RateLimiter()


def get_client_ip(request: Request) -> str:
    """
    获取客户端 IP 地址
    
    Args:
        request: FastAPI 请求对象
        
    Returns:
        IP 地址字符串
    """
    # 优先从 X-Forwarded-For 获取（代理场景）
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()
    
    # 从 X-Real-IP 获取
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip
    
    # 从客户端获取
    if request.client:
        return request.client.host
    
    return "unknown"


async def rate_limit_middleware(request: Request, call_next):
    """
    限流中间件
    
    根据 IP 地址或用户 ID 进行限流
    """
    # 检查是否是公开路径（健康检查等不需要限流）
    if request.url.path in ["/health", "/docs", "/redoc", "/openapi.json"]:
        response = await call_next(request)
        return response
    
    # 获取限流键
    client_ip = get_client_ip(request)
    # 如果有用户信息，使用用户 ID 作为限流键
    user_id = getattr(request.state, "user", {}).get("user_id")
    rate_limit_key = f"user:{user_id}" if user_id else f"ip:{client_ip}"
    
    # 检查限流
    is_allowed, remaining = rate_limiter.is_allowed(
        rate_limit_key,
        settings.RATE_LIMIT_REQUESTS,
        settings.RATE_LIMIT_WINDOW
    )
    
    if not is_allowed:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"请求过于频繁，请稍后再试。限制：{settings.RATE_LIMIT_REQUESTS} 次/{settings.RATE_LIMIT_WINDOW}秒",
            headers={
                "X-RateLimit-Limit": str(settings.RATE_LIMIT_REQUESTS),
                "X-RateLimit-Remaining": str(remaining),
                "X-RateLimit-Reset": str(int(time.time()) + settings.RATE_LIMIT_WINDOW),
            }
        )
    
    # 添加限流信息到响应头
    response = await call_next(request)
    response.headers["X-RateLimit-Limit"] = str(settings.RATE_LIMIT_REQUESTS)
    response.headers["X-RateLimit-Remaining"] = str(remaining)
    response.headers["X-RateLimit-Reset"] = str(int(time.time()) + settings.RATE_LIMIT_WINDOW)
    
    return response
