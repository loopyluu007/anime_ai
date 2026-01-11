"""权限检查工具函数"""
from shared.models.db_models import User


def is_admin(user: User) -> bool:
    """
    检查用户是否是管理员
    
    Args:
        user: 用户对象
        
    Returns:
        如果是管理员返回True，否则返回False
    """
    return getattr(user, 'is_admin', False) is True
