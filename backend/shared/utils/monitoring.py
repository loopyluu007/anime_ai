"""监控和告警工具"""
import time
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from collections import defaultdict
from shared.config.redis import get_redis
from shared.utils.logger import setup_logger

logger = setup_logger(__name__)

class MetricsCollector:
    """指标收集器"""
    
    def __init__(self, redis_client=None):
        self.redis = redis_client or get_redis()
        self.metrics_prefix = "metrics:"
    
    def record_request(
        self,
        endpoint: str,
        method: str,
        status_code: int,
        duration_ms: float,
        user_id: Optional[str] = None
    ):
        """记录请求指标"""
        timestamp = int(time.time())
        date_key = datetime.utcnow().strftime("%Y-%m-%d")
        
        # 记录请求计数
        self.redis.incr(f"{self.metrics_prefix}requests:total:{date_key}")
        self.redis.incr(f"{self.metrics_prefix}requests:endpoint:{endpoint}:{date_key}")
        self.redis.incr(f"{self.metrics_prefix}requests:status:{status_code}:{date_key}")
        
        # 记录响应时间
        self.redis.lpush(f"{self.metrics_prefix}response_time:{endpoint}", duration_ms)
        self.redis.ltrim(f"{self.metrics_prefix}response_time:{endpoint}", 0, 999)  # 保留最近1000条
        
        # 记录用户请求（如果提供）
        if user_id:
            self.redis.incr(f"{self.metrics_prefix}requests:user:{user_id}:{date_key}")
    
    def record_error(
        self,
        error_type: str,
        endpoint: str,
        error_message: str,
        user_id: Optional[str] = None
    ):
        """记录错误指标"""
        date_key = datetime.utcnow().strftime("%Y-%m-%d")
        
        self.redis.incr(f"{self.metrics_prefix}errors:total:{date_key}")
        self.redis.incr(f"{self.metrics_prefix}errors:type:{error_type}:{date_key}")
        self.redis.incr(f"{self.metrics_prefix}errors:endpoint:{endpoint}:{date_key}")
        
        if user_id:
            self.redis.incr(f"{self.metrics_prefix}errors:user:{user_id}:{date_key}")
    
    def get_metrics(
        self,
        date: Optional[str] = None,
        endpoint: Optional[str] = None
    ) -> Dict[str, Any]:
        """获取指标数据"""
        if not date:
            date = datetime.utcnow().strftime("%Y-%m-%d")
        
        metrics = {
            "date": date,
            "total_requests": int(self.redis.get(f"{self.metrics_prefix}requests:total:{date}") or 0),
            "total_errors": int(self.redis.get(f"{self.metrics_prefix}errors:total:{date}") or 0),
        }
        
        if endpoint:
            metrics["endpoint"] = endpoint
            metrics["endpoint_requests"] = int(
                self.redis.get(f"{self.metrics_prefix}requests:endpoint:{endpoint}:{date}") or 0
            )
            metrics["endpoint_errors"] = int(
                self.redis.get(f"{self.metrics_prefix}errors:endpoint:{endpoint}:{date}") or 0
            )
            
            # 获取平均响应时间
            response_times = self.redis.lrange(
                f"{self.metrics_prefix}response_time:{endpoint}", 0, -1
            )
            if response_times:
                avg_time = sum(float(t) for t in response_times) / len(response_times)
                metrics["avg_response_time_ms"] = round(avg_time, 2)
        
        return metrics

class AlertManager:
    """告警管理器"""
    
    def __init__(self, redis_client=None):
        self.redis = redis_client or get_redis()
        self.alert_prefix = "alerts:"
    
    def check_error_rate(
        self,
        threshold: float = 0.1,
        window_minutes: int = 5
    ) -> bool:
        """检查错误率是否超过阈值"""
        now = datetime.utcnow()
        window_start = now - timedelta(minutes=window_minutes)
        
        # 获取窗口内的请求数和错误数
        total_requests = 0
        total_errors = 0
        
        for i in range(window_minutes):
            date_key = (now - timedelta(minutes=i)).strftime("%Y-%m-%d")
            hour_minute = (now - timedelta(minutes=i)).strftime("%H:%M")
            
            requests = int(self.redis.get(f"{self.alert_prefix}requests:{date_key}:{hour_minute}") or 0)
            errors = int(self.redis.get(f"{self.alert_prefix}errors:{date_key}:{hour_minute}") or 0)
            
            total_requests += requests
            total_errors += errors
        
        if total_requests == 0:
            return False
        
        error_rate = total_errors / total_requests
        return error_rate > threshold
    
    def check_response_time(
        self,
        endpoint: str,
        threshold_ms: float = 1000,
        window_size: int = 100
    ) -> bool:
        """检查响应时间是否超过阈值"""
        response_times = self.redis.lrange(
            f"metrics:response_time:{endpoint}", 0, window_size - 1
        )
        
        if not response_times:
            return False
        
        avg_time = sum(float(t) for t in response_times) / len(response_times)
        return avg_time > threshold_ms
    
    def send_alert(
        self,
        alert_type: str,
        message: str,
        severity: str = "warning"
    ):
        """发送告警"""
        alert_data = {
            "type": alert_type,
            "message": message,
            "severity": severity,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # 存储告警
        alert_key = f"{self.alert_prefix}{alert_type}:{int(time.time())}"
        self.redis.setex(alert_key, 86400, str(alert_data))  # 保留24小时
        
        # 记录日志
        if severity == "critical":
            logger.critical(f"ALERT [{alert_type}]: {message}")
        elif severity == "error":
            logger.error(f"ALERT [{alert_type}]: {message}")
        else:
            logger.warning(f"ALERT [{alert_type}]: {message}")

# 全局实例
metrics_collector = MetricsCollector()
alert_manager = AlertManager()
