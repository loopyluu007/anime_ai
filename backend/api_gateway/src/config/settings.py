"""
API Gateway 配置管理
"""
import os
from typing import Dict, List
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """API Gateway 配置"""
    
    # 服务地址配置
    AGENT_SERVICE_URL: str = os.getenv(
        "AGENT_SERVICE_URL", 
        "http://localhost:8001"
    )
    MEDIA_SERVICE_URL: str = os.getenv(
        "MEDIA_SERVICE_URL", 
        "http://localhost:8002"
    )
    DATA_SERVICE_URL: str = os.getenv(
        "DATA_SERVICE_URL", 
        "http://localhost:8003"
    )
    
    # JWT 配置
    SECRET_KEY: str = os.getenv(
        "SECRET_KEY", 
        "your-secret-key-change-in-production"
    )
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(
        os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60")
    )
    
    # 限流配置
    RATE_LIMIT_ENABLED: bool = os.getenv("RATE_LIMIT_ENABLED", "true").lower() == "true"
    RATE_LIMIT_REQUESTS: int = int(os.getenv("RATE_LIMIT_REQUESTS", "100"))
    RATE_LIMIT_WINDOW: int = int(os.getenv("RATE_LIMIT_WINDOW", "60"))  # 秒
    
    # CORS 配置
    CORS_ORIGINS: List[str] = os.getenv(
        "CORS_ORIGINS", 
        "*"
    ).split(",")
    CORS_CREDENTIALS: bool = os.getenv("CORS_CREDENTIALS", "true").lower() == "true"
    CORS_METHODS: List[str] = os.getenv(
        "CORS_METHODS", 
        "GET,POST,PUT,DELETE,OPTIONS"
    ).split(",")
    CORS_HEADERS: List[str] = os.getenv(
        "CORS_HEADERS", 
        "*"
    ).split(",")
    
    # 路由配置
    ROUTE_PREFIX: str = "/api/v1"
    
    # 健康检查路径（不需要认证）
    PUBLIC_PATHS: List[str] = [
        "/health",
        "/docs",
        "/redoc",
        "/openapi.json",
        "/api/v1/auth/login",
        "/api/v1/auth/register",
    ]
    
    class Config:
        env_file = ".env"
        case_sensitive = True
    
    def get_service_routes(self) -> Dict[str, str]:
        """获取服务路由映射"""
        return {
            "/api/v1/auth": self.AGENT_SERVICE_URL,
            "/api/v1/conversations": self.AGENT_SERVICE_URL,
            "/api/v1/tasks": self.AGENT_SERVICE_URL,
            "/api/v1/screenplays": self.AGENT_SERVICE_URL,
            "/api/v1/images": self.MEDIA_SERVICE_URL,
            "/api/v1/videos": self.MEDIA_SERVICE_URL,
            "/api/v1/users": self.DATA_SERVICE_URL,
            "/api/v1/analytics": self.DATA_SERVICE_URL,
        }
    
    def get_websocket_routes(self) -> Dict[str, str]:
        """获取WebSocket路由映射"""
        return {
            "/ws": self.AGENT_SERVICE_URL,
        }


# 全局配置实例
settings = Settings()
