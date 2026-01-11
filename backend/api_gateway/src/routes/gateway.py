"""
API Gateway 路由转发
"""
from fastapi import APIRouter, Request, Response, HTTPException, status
from fastapi.responses import StreamingResponse
import httpx
from typing import Optional
import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from api_gateway.src.config.settings import settings


router = APIRouter()


async def forward_request(
    request: Request,
    target_url: str,
    path: str,
    method: str = "GET"
) -> Response:
    """
    转发请求到目标服务
    
    Args:
        request: 原始请求
        target_url: 目标服务 URL
        path: 请求路径
        method: HTTP 方法
        
    Returns:
        目标服务的响应
    """
    # 构建完整的目标 URL
    full_url = f"{target_url.rstrip('/')}{path}"
    
    # 获取请求体
    body = None
    if request.method in ["POST", "PUT", "PATCH"]:
        try:
            body = await request.body()
        except Exception:
            body = None
    
    # 准备请求头（排除一些不需要转发的头）
    headers = {}
    for key, value in request.headers.items():
        # 跳过一些不需要转发的头
        if key.lower() in ["host", "content-length", "connection"]:
            continue
        headers[key] = value
    
    # 如果有用户信息，添加到请求头
    if hasattr(request.state, "user") and request.state.user:
        user = request.state.user
        if user:
            headers["X-User-ID"] = str(user.get("user_id", ""))
            headers["X-Username"] = user.get("username", "")
    
    # 转发请求
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
        try:
            response = await client.request(
                method=method or request.method,
                url=full_url,
                headers=headers,
                content=body,
                params=dict(request.query_params),
            )
            
            # 创建响应
            response_headers = dict(response.headers)
            # 移除一些不需要的响应头
            response_headers.pop("content-encoding", None)
            response_headers.pop("transfer-encoding", None)
            
            return Response(
                content=response.content,
                status_code=response.status_code,
                headers=response_headers,
                media_type=response.headers.get("content-type"),
            )
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="请求超时，请稍后重试"
            )
        except httpx.ConnectError:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="服务暂时不可用，请稍后重试"
            )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"网关错误: {str(e)}"
            )


def find_target_service(path: str) -> Optional[str]:
    """
    根据路径找到目标服务 URL
    
    Args:
        path: 请求路径
        
    Returns:
        目标服务 URL，如果未找到则返回 None
    """
    # 检查服务路由映射
    service_routes = settings.get_service_routes()
    for route_prefix, service_url in service_routes.items():
        if path.startswith(route_prefix):
            return service_url
    
    return None


@router.api_route(
    "/{path:path}",
    methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    include_in_schema=False
)
async def gateway_route(request: Request, path: str):
    """
    API Gateway 主路由
    
    根据路径转发请求到对应的服务
    """
    # 处理根路径和健康检查
    if path == "" or path == "/":
        return {"message": "AI漫导 API Gateway", "version": "1.0.0"}
    
    if path == "/health":
        # 检查各个服务的健康状态
        services_status = {}
        async with httpx.AsyncClient(timeout=5.0) as client:
            for service_name, service_url in [
                ("agent_service", settings.AGENT_SERVICE_URL),
                ("media_service", settings.MEDIA_SERVICE_URL),
                ("data_service", settings.DATA_SERVICE_URL),
            ]:
                try:
                    response = await client.get(f"{service_url}/health")
                    services_status[service_name] = {
                        "status": "healthy" if response.status_code == 200 else "unhealthy",
                        "url": service_url
                    }
                except Exception:
                    services_status[service_name] = {
                        "status": "unreachable",
                        "url": service_url
                    }
        
        return {
            "status": "healthy",
            "gateway": "running",
            "services": services_status
        }
    
    # 查找目标服务
    full_path = f"/{path}" if not path.startswith("/") else path
    target_url = find_target_service(full_path)
    
    if not target_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"未找到对应的服务: {full_path}"
        )
    
    # 转发请求
    return await forward_request(request, target_url, full_path)
