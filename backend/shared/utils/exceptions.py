from fastapi import HTTPException, status

class DirectorAIException(HTTPException):
    """基础异常类"""
    def __init__(self, status_code: int, detail: str, error_code: int = None):
        super().__init__(status_code=status_code, detail=detail)
        self.error_code = error_code

class ValidationError(DirectorAIException):
    """参数验证错误"""
    def __init__(self, detail: str, field: str = None):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=detail,
            error_code=1000
        )
        self.field = field

class AuthenticationError(DirectorAIException):
    """认证错误"""
    def __init__(self, detail: str = "认证失败"):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=detail,
            error_code=2000
        )

class NotFoundError(DirectorAIException):
    """资源不存在"""
    def __init__(self, resource: str = "资源"):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"{resource}不存在",
            error_code=3000
        )
