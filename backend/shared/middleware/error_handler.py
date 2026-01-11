"""统一错误处理中间件"""
import time
import uuid
from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from typing import Callable

from shared.utils.exceptions import DirectorAIException
from shared.utils.logger import setup_logger, log_error
from shared.utils.monitoring import metrics_collector

logger = setup_logger(__name__)

async def error_handler_middleware(request: Request, call_next: Callable):
    """
    统一错误处理中间件
    
    捕获所有异常并返回统一的错误响应格式
    """
    start_time = time.time()
    error_id = str(uuid.uuid4())
    
    try:
        response = await call_next(request)
        
        # 记录请求日志和指标
        duration_ms = (time.time() - start_time) * 1000
        user_id = getattr(request.state, "user_id", None) if hasattr(request.state, "user") else None
        user_id_str = str(user_id) if user_id else None
        
        # 记录指标
        try:
            metrics_collector.record_request(
                endpoint=str(request.url.path),
                method=request.method,
                status_code=response.status_code,
                duration_ms=duration_ms,
                user_id=user_id_str
            )
        except Exception as e:
            logger.warning(f"Failed to record metrics: {e}")
        
        logger.info(
            f"{request.method} {request.url.path} - {response.status_code} - {duration_ms:.2f}ms",
            extra={
                "extra_data": {
                    "method": request.method,
                    "path": str(request.url.path),
                    "status_code": response.status_code,
                    "duration_ms": duration_ms,
                    "user_id": user_id_str,
                    "client_ip": request.client.host if request.client else None,
                }
            }
        )
        
        return response
        
    except DirectorAIException as e:
        # 自定义异常
        duration_ms = (time.time() - start_time) * 1000
        user_id_str = str(getattr(request.state, "user_id", None)) if hasattr(request.state, "user") else None
        
        # 记录错误指标
        try:
            metrics_collector.record_error(
                error_type=type(e).__name__,
                endpoint=str(request.url.path),
                error_message=e.detail,
                user_id=user_id_str
            )
        except Exception as metric_error:
            logger.warning(f"Failed to record error metrics: {metric_error}")
        
        log_error(
            logger,
            e,
            context={
                "error_id": error_id,
                "method": request.method,
                "path": str(request.url.path),
                "duration_ms": duration_ms,
            },
            user_id=user_id_str
        )
        
        return JSONResponse(
            status_code=e.status_code,
            content={
                "error": {
                    "code": e.error_code or 0,
                    "message": e.detail,
                    "error_id": error_id,
                    "data": e.error_data
                }
            }
        )
        
    except RequestValidationError as e:
        # 请求验证错误
        duration_ms = (time.time() - start_time) * 1000
        logger.warning(
            f"Validation error: {e.errors()}",
            extra={
                "extra_data": {
                    "error_id": error_id,
                    "method": request.method,
                    "path": str(request.url.path),
                    "validation_errors": e.errors(),
                }
            }
        )
        
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "error": {
                    "code": 1000,
                    "message": "请求参数验证失败",
                    "error_id": error_id,
                    "data": {
                        "errors": e.errors()
                    }
                }
            }
        )
        
    except StarletteHTTPException as e:
        # FastAPI HTTP异常
        duration_ms = (time.time() - start_time) * 1000
        log_error(
            logger,
            e,
            context={
                "error_id": error_id,
                "method": request.method,
                "path": str(request.url.path),
                "duration_ms": duration_ms,
            }
        )
        
        return JSONResponse(
            status_code=e.status_code,
            content={
                "error": {
                    "code": e.status_code * 10,
                    "message": e.detail,
                    "error_id": error_id,
                    "data": {}
                }
            }
        )
        
    except Exception as e:
        # 未预期的异常
        duration_ms = (time.time() - start_time) * 1000
        user_id_str = str(getattr(request.state, "user_id", None)) if hasattr(request.state, "user") else None
        
        # 记录错误指标
        try:
            metrics_collector.record_error(
                error_type=type(e).__name__,
                endpoint=str(request.url.path),
                error_message=str(e),
                user_id=user_id_str
            )
        except Exception as metric_error:
            logger.warning(f"Failed to record error metrics: {metric_error}")
        
        log_error(
            logger,
            e,
            context={
                "error_id": error_id,
                "method": request.method,
                "path": str(request.url.path),
                "duration_ms": duration_ms,
            },
            user_id=user_id_str
        )
        
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "error": {
                    "code": 6000,
                    "message": "服务器内部错误",
                    "error_id": error_id,
                    "data": {}
                }
            }
        )
