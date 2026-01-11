from fastapi import HTTPException, status
from typing import Optional, Dict, Any

class DirectorAIException(HTTPException):
    """基础异常类"""
    def __init__(
        self, 
        status_code: int, 
        detail: str, 
        error_code: int = None,
        error_data: Optional[Dict[str, Any]] = None
    ):
        super().__init__(status_code=status_code, detail=detail)
        self.error_code = error_code
        self.error_data = error_data or {}

class ValidationError(DirectorAIException):
    """参数验证错误"""
    def __init__(self, detail: str, field: str = None, errors: Optional[Dict[str, Any]] = None):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=detail,
            error_code=1000,
            error_data={"field": field, "errors": errors} if field or errors else {}
        )
        self.field = field
        self.errors = errors

class AuthenticationError(DirectorAIException):
    """认证错误"""
    def __init__(self, detail: str = "认证失败", reason: Optional[str] = None):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            error_code=2000,
            error_data={"reason": reason} if reason else {}
        )

class AuthorizationError(DirectorAIException):
    """授权错误（权限不足）"""
    def __init__(self, detail: str = "权限不足", resource: Optional[str] = None):
        super().__init__(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=detail,
            error_code=2001,
            error_data={"resource": resource} if resource else {}
        )

class NotFoundError(DirectorAIException):
    """资源不存在"""
    def __init__(self, resource: str = "资源", resource_id: Optional[str] = None):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{resource}不存在",
            error_code=3000,
            error_data={"resource": resource, "resource_id": resource_id} if resource_id else {"resource": resource}
        )

class ConflictError(DirectorAIException):
    """资源冲突错误（如重复创建）"""
    def __init__(self, detail: str = "资源已存在", resource: Optional[str] = None):
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=detail,
            error_code=4000,
            error_data={"resource": resource} if resource else {}
        )

class RateLimitError(DirectorAIException):
    """限流错误"""
    def __init__(self, detail: str = "请求过于频繁，请稍后再试", retry_after: Optional[int] = None):
        super().__init__(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=detail,
            error_code=5000,
            error_data={"retry_after": retry_after} if retry_after else {}
        )

class InternalServerError(DirectorAIException):
    """内部服务器错误"""
    def __init__(self, detail: str = "服务器内部错误", error_id: Optional[str] = None):
        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=detail,
            error_code=6000,
            error_data={"error_id": error_id} if error_id else {}
        )

class ServiceUnavailableError(DirectorAIException):
    """服务不可用错误"""
    def __init__(self, detail: str = "服务暂时不可用，请稍后重试", service: Optional[str] = None):
        super().__init__(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=detail,
            error_code=7000,
            error_data={"service": service} if service else {}
        )

class TimeoutError(DirectorAIException):
    """请求超时错误"""
    def __init__(self, detail: str = "请求超时，请稍后重试", timeout: Optional[int] = None):
        super().__init__(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail=detail,
            error_code=8000,
            error_data={"timeout": timeout} if timeout else {}
        )
