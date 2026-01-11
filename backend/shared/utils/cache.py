"""缓存工具类"""
import json
import hashlib
from typing import Optional, Any, Callable
from functools import wraps
from shared.config.redis import get_redis
from shared.utils.logger import setup_logger

logger = setup_logger(__name__)

class CacheManager:
    """缓存管理器"""
    
    def __init__(self, redis_client=None, default_ttl: int = 300):
        """
        初始化缓存管理器
        
        Args:
            redis_client: Redis客户端（可选，默认使用共享客户端）
            default_ttl: 默认过期时间（秒），默认5分钟
        """
        self.redis = redis_client or get_redis()
        self.default_ttl = default_ttl
    
    def _make_key(self, prefix: str, *args, **kwargs) -> str:
        """生成缓存键"""
        key_parts = [prefix]
        
        # 添加位置参数
        for arg in args:
            key_parts.append(str(arg))
        
        # 添加关键字参数
        if kwargs:
            sorted_kwargs = sorted(kwargs.items())
            key_parts.append(json.dumps(sorted_kwargs, sort_keys=True))
        
        key_string = ":".join(key_parts)
        # 如果键太长，使用哈希
        if len(key_string) > 200:
            key_hash = hashlib.md5(key_string.encode()).hexdigest()
            return f"{prefix}:hash:{key_hash}"
        
        return key_string
    
    def get(self, key: str) -> Optional[Any]:
        """获取缓存值"""
        try:
            value = self.redis.get(key)
            if value is None:
                return None
            return json.loads(value)
        except Exception as e:
            logger.warning(f"Cache get error for key {key}: {e}")
            return None
    
    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """设置缓存值"""
        try:
            ttl = ttl or self.default_ttl
            serialized = json.dumps(value, ensure_ascii=False, default=str)
            return self.redis.setex(key, ttl, serialized)
        except Exception as e:
            logger.warning(f"Cache set error for key {key}: {e}")
            return False
    
    def delete(self, key: str) -> bool:
        """删除缓存值"""
        try:
            return bool(self.redis.delete(key))
        except Exception as e:
            logger.warning(f"Cache delete error for key {key}: {e}")
            return False
    
    def delete_pattern(self, pattern: str) -> int:
        """删除匹配模式的所有键"""
        try:
            keys = self.redis.keys(pattern)
            if keys:
                return self.redis.delete(*keys)
            return 0
        except Exception as e:
            logger.warning(f"Cache delete_pattern error for pattern {pattern}: {e}")
            return 0
    
    def clear_user_cache(self, user_id: str):
        """清除用户相关的所有缓存"""
        patterns = [
            f"user:{user_id}:*",
            f"stats:user:{user_id}:*",
            f"conversations:user:{user_id}:*",
            f"tasks:user:{user_id}:*",
        ]
        total_deleted = 0
        for pattern in patterns:
            total_deleted += self.delete_pattern(pattern)
        return total_deleted

# 全局缓存管理器实例
cache_manager = CacheManager()

def cached(
    prefix: str,
    ttl: Optional[int] = None,
    key_func: Optional[Callable] = None
):
    """
    缓存装饰器
    
    Args:
        prefix: 缓存键前缀
        ttl: 过期时间（秒）
        key_func: 自定义键生成函数
    """
    def decorator(func: Callable):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            # 生成缓存键
            if key_func:
                cache_key = key_func(*args, **kwargs)
            else:
                cache_key = cache_manager._make_key(prefix, *args, **kwargs)
            
            # 尝试从缓存获取
            cached_value = cache_manager.get(cache_key)
            if cached_value is not None:
                logger.debug(f"Cache hit: {cache_key}")
                return cached_value
            
            # 执行函数
            logger.debug(f"Cache miss: {cache_key}")
            result = await func(*args, **kwargs)
            
            # 存入缓存
            cache_manager.set(cache_key, result, ttl)
            
            return result
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            # 生成缓存键
            if key_func:
                cache_key = key_func(*args, **kwargs)
            else:
                cache_key = cache_manager._make_key(prefix, *args, **kwargs)
            
            # 尝试从缓存获取
            cached_value = cache_manager.get(cache_key)
            if cached_value is not None:
                logger.debug(f"Cache hit: {cache_key}")
                return cached_value
            
            # 执行函数
            logger.debug(f"Cache miss: {cache_key}")
            result = func(*args, **kwargs)
            
            # 存入缓存
            cache_manager.set(cache_key, result, ttl)
            
            return result
        
        # 判断是否是协程函数
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator
