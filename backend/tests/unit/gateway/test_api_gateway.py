"""API Gateway单元测试"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi import Request, status
from fastapi.testclient import TestClient
from fastapi.responses import JSONResponse
import sys
from pathlib import Path
import os
from datetime import datetime, timedelta

# 设置测试环境变量
os.environ["TESTING"] = "true"
os.environ["SECRET_KEY"] = "test-secret-key-for-api-gateway-testing"
os.environ["AGENT_SERVICE_URL"] = "http://localhost:8001"
os.environ["MEDIA_SERVICE_URL"] = "http://localhost:8002"
os.environ["DATA_SERVICE_URL"] = "http://localhost:8003"
os.environ["RATE_LIMIT_ENABLED"] = "true"
os.environ["RATE_LIMIT_REQUESTS"] = "100"
os.environ["RATE_LIMIT_WINDOW"] = "60"

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

# 尝试导入jose，如果失败则跳过JWT相关测试
try:
    from jose import jwt
    JWT_AVAILABLE = True
except ImportError:
    JWT_AVAILABLE = False
    pytest.skip("jose library not available", allow_module_level=True)

# 尝试导入API Gateway模块，如果依赖缺失则跳过
try:
    from api_gateway.src.middleware.auth import verify_token, get_current_user
    from api_gateway.src.middleware.rate_limit import RateLimiter, rate_limit_middleware, get_client_ip
    from api_gateway.src.routes.gateway import find_target_service, forward_request
    GATEWAY_AVAILABLE = True
except ImportError as e:
    GATEWAY_AVAILABLE = False
    pytest.skip(f"API Gateway dependencies not available: {e}", allow_module_level=True)

try:
    from api_gateway.src.main import app
except ImportError as e:
    app = None
    pytest.skip(f"Cannot import API Gateway app: {e}", allow_module_level=True)


@pytest.mark.unit
@pytest.mark.skipif(not JWT_AVAILABLE or not GATEWAY_AVAILABLE, reason="Dependencies not available")
class TestAuthMiddleware:
    """认证中间件测试"""
    
    @pytest.mark.asyncio
    async def test_verify_token_valid(self):
        """测试验证有效Token"""
        secret_key = "test-secret-key-for-api-gateway-testing"
        token = jwt.encode(
            {
                "sub": "user123",
                "username": "testuser",
                "email": "test@example.com",
                "exp": datetime.utcnow() + timedelta(hours=1)
            },
            secret_key,
            algorithm="HS256"
        )
        
        payload = await verify_token(token)
        
        assert payload is not None
        assert payload["sub"] == "user123"
        assert payload["username"] == "testuser"
    
    @pytest.mark.asyncio
    async def test_verify_token_invalid(self):
        """测试验证无效Token"""
        payload = await verify_token("invalid-token")
        assert payload is None
    
    @pytest.mark.asyncio
    async def test_verify_token_expired(self):
        """测试验证过期Token"""
        secret_key = "test-secret-key-for-api-gateway-testing"
        token = jwt.encode(
            {
                "sub": "user123",
                "exp": datetime.utcnow() - timedelta(hours=1)  # 已过期
            },
            secret_key,
            algorithm="HS256"
        )
        
        payload = await verify_token(token)
        assert payload is None
    
    @pytest.mark.asyncio
    async def test_get_current_user_with_valid_token(self):
        """测试从有效Token获取用户信息"""
        secret_key = "test-secret-key-for-api-gateway-testing"
        token = jwt.encode(
            {
                "sub": "user123",
                "username": "testuser",
                "email": "test@example.com",
                "exp": datetime.utcnow() + timedelta(hours=1)
            },
            secret_key,
            algorithm="HS256"
        )
        
        # 创建模拟请求
        request = MagicMock(spec=Request)
        request.headers = {"Authorization": f"Bearer {token}"}
        
        user = await get_current_user(request)
        
        assert user is not None
        assert user["user_id"] == "user123"
        assert user["username"] == "testuser"
        assert user["email"] == "test@example.com"
    
    @pytest.mark.asyncio
    async def test_get_current_user_without_token(self):
        """测试无Token获取用户信息"""
        request = MagicMock(spec=Request)
        request.headers = {}
        
        user = await get_current_user(request)
        
        assert user is None
    
    @pytest.mark.asyncio
    async def test_get_current_user_with_invalid_token(self):
        """测试无效Token获取用户信息"""
        request = MagicMock(spec=Request)
        request.headers = {"Authorization": "Bearer invalid-token"}
        
        user = await get_current_user(request)
        
        assert user is None


@pytest.mark.unit
@pytest.mark.skipif(not GATEWAY_AVAILABLE, reason="API Gateway dependencies not available")
class TestRateLimitMiddleware:
    """限流中间件测试"""
    
    def test_rate_limiter_allow(self):
        """测试限流器允许请求"""
        limiter = RateLimiter()
        key = "test_key"
        max_requests = 10
        window = 60
        
        # 第一次请求应该允许
        allowed, remaining = limiter.is_allowed(key, max_requests, window)
        assert allowed is True
        assert remaining >= 0
    
    def test_rate_limiter_limit(self):
        """测试限流器限制请求"""
        limiter = RateLimiter()
        key = "test_key_limit"
        max_requests = 3
        window = 60
        
        # 前3次请求应该允许
        for i in range(3):
            allowed, remaining = limiter.is_allowed(key, max_requests, window)
            assert allowed is True
        
        # 第4次请求应该被限制
        allowed, remaining = limiter.is_allowed(key, max_requests, window)
        assert allowed is False
        assert remaining == 0
    
    def test_rate_limiter_disabled(self):
        """测试限流器禁用时允许所有请求"""
        with patch('api_gateway.src.middleware.rate_limit.settings') as mock_settings:
            mock_settings.RATE_LIMIT_ENABLED = False
            limiter = RateLimiter()
            
            allowed, remaining = limiter.is_allowed("test_key", 1, 60)
            assert allowed is True
            assert remaining == 1
    
    def test_get_client_ip_from_forwarded(self):
        """测试从X-Forwarded-For获取IP"""
        request = MagicMock(spec=Request)
        request.headers = {"X-Forwarded-For": "192.168.1.1, 10.0.0.1"}
        request.client = None
        
        ip = get_client_ip(request)
        assert ip == "192.168.1.1"
    
    def test_get_client_ip_from_real_ip(self):
        """测试从X-Real-IP获取IP"""
        request = MagicMock(spec=Request)
        request.headers = {"X-Real-IP": "192.168.1.2"}
        request.client = None
        
        ip = get_client_ip(request)
        assert ip == "192.168.1.2"
    
    def test_get_client_ip_from_client(self):
        """测试从客户端获取IP"""
        request = MagicMock(spec=Request)
        request.headers = {}
        request.client = MagicMock()
        request.client.host = "192.168.1.3"
        
        ip = get_client_ip(request)
        assert ip == "192.168.1.3"


@pytest.mark.unit
@pytest.mark.skipif(not GATEWAY_AVAILABLE, reason="API Gateway dependencies not available")
class TestGatewayRoutes:
    """网关路由测试"""
    
    def test_find_target_service_auth(self):
        """测试查找认证服务"""
        path = "/api/v1/auth/login"
        url = find_target_service(path)
        assert url == "http://localhost:8001"
    
    def test_find_target_service_conversations(self):
        """测试查找对话服务"""
        path = "/api/v1/conversations"
        url = find_target_service(path)
        assert url == "http://localhost:8001"
    
    def test_find_target_service_images(self):
        """测试查找图片服务"""
        path = "/api/v1/images"
        url = find_target_service(path)
        assert url == "http://localhost:8002"
    
    def test_find_target_service_videos(self):
        """测试查找视频服务"""
        path = "/api/v1/videos"
        url = find_target_service(path)
        assert url == "http://localhost:8002"
    
    def test_find_target_service_users(self):
        """测试查找用户服务"""
        path = "/api/v1/users"
        url = find_target_service(path)
        assert url == "http://localhost:8003"
    
    def test_find_target_service_not_found(self):
        """测试查找不存在的服务"""
        path = "/api/v1/unknown"
        url = find_target_service(path)
        assert url is None


@pytest.mark.unit
@pytest.mark.skipif(not GATEWAY_AVAILABLE or app is None, reason="API Gateway app not available")
class TestGatewayApp:
    """API Gateway应用测试"""
    
    def test_root_endpoint(self):
        """测试根路径"""
        if app is None:
            pytest.skip("API Gateway app not available")
        client = TestClient(app)
        response = client.get("/")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "message" in data
        assert data["message"] == "AI漫导 API Gateway"
    
    def test_health_endpoint(self):
        """测试健康检查"""
        if app is None:
            pytest.skip("API Gateway app not available")
        client = TestClient(app)
        response = client.get("/health")
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "status" in data
        assert data["status"] == "healthy"
    
    def test_public_paths_allowed(self):
        """测试公开路径不需要认证"""
        if app is None:
            pytest.skip("API Gateway app not available")
        client = TestClient(app)
        
        # 健康检查不需要认证
        response = client.get("/health")
        assert response.status_code == status.HTTP_200_OK
        
        # 文档不需要认证
        response = client.get("/docs")
        assert response.status_code == status.HTTP_200_OK
    
    def test_protected_path_requires_auth(self):
        """测试保护路径需要认证"""
        if app is None:
            pytest.skip("API Gateway app not available")
        client = TestClient(app)
        
        # 尝试访问需要认证的路径（没有Token）
        response = client.get("/api/v1/conversations")
        
        # 应该返回401未授权
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
