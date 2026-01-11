import logging
import sys
import os
import json
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, Any

class JSONFormatter(logging.Formatter):
    """JSON格式的日志格式化器"""
    def format(self, record: logging.LogRecord) -> str:
        log_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }
        
        # 添加异常信息
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        # 添加额外字段
        if hasattr(record, "extra_data"):
            log_data["extra"] = record.extra_data
        
        return json.dumps(log_data, ensure_ascii=False)

def setup_logger(
    name: str, 
    level: int = logging.INFO,
    log_file: Optional[str] = None,
    use_json: bool = False,
    log_dir: str = "logs"
) -> logging.Logger:
    """
    设置日志记录器
    
    Args:
        name: 日志记录器名称
        level: 日志级别
        log_file: 日志文件路径（可选）
        use_json: 是否使用JSON格式
        log_dir: 日志目录（默认logs）
    """
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # 避免重复添加handler
    if logger.handlers:
        return logger
    
    # 控制台输出
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    
    if use_json:
        console_formatter = JSONFormatter()
    else:
        console_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s [%(module)s:%(funcName)s:%(lineno)d]',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
    
    console_handler.setFormatter(console_formatter)
    logger.addHandler(console_handler)
    
    # 文件输出（如果指定）
    if log_file:
        # 确保日志目录存在
        log_path = Path(log_dir)
        log_path.mkdir(parents=True, exist_ok=True)
        
        file_path = log_path / log_file
        
        file_handler = logging.FileHandler(file_path, encoding='utf-8')
        file_handler.setLevel(level)
        
        if use_json:
            file_formatter = JSONFormatter()
        else:
            file_formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s [%(module)s:%(funcName)s:%(lineno)d]',
                datefmt='%Y-%m-%d %H:%M:%S'
            )
        
        file_handler.setFormatter(file_formatter)
        logger.addHandler(file_handler)
    
    return logger

def get_log_level(level_name: str) -> int:
    """根据名称获取日志级别"""
    level_map = {
        "DEBUG": logging.DEBUG,
        "INFO": logging.INFO,
        "WARNING": logging.WARNING,
        "ERROR": logging.ERROR,
        "CRITICAL": logging.CRITICAL,
    }
    return level_map.get(level_name.upper(), logging.INFO)

def log_request(
    logger: logging.Logger,
    method: str,
    path: str,
    status_code: int,
    duration_ms: float,
    user_id: Optional[str] = None,
    **kwargs
):
    """记录HTTP请求日志"""
    extra_data = {
        "method": method,
        "path": path,
        "status_code": status_code,
        "duration_ms": duration_ms,
        "user_id": user_id,
        **kwargs
    }
    logger.info(
        f"{method} {path} - {status_code} - {duration_ms:.2f}ms",
        extra={"extra_data": extra_data}
    )

def log_error(
    logger: logging.Logger,
    error: Exception,
    context: Optional[Dict[str, Any]] = None,
    user_id: Optional[str] = None
):
    """记录错误日志"""
    extra_data = {
        "error_type": type(error).__name__,
        "error_message": str(error),
        "user_id": user_id,
        **(context or {})
    }
    logger.error(
        f"Error: {type(error).__name__} - {str(error)}",
        exc_info=True,
        extra={"extra_data": extra_data}
    )
