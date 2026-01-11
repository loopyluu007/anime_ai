"""用户数据服务"""
from sqlalchemy.orm import Session
from uuid import UUID
from typing import Optional, Dict, Any
from shared.models.db_models import User
from services.data_service.src.repositories.user_repository import UserRepository

class UserService:
    """用户数据服务"""
    
    def __init__(self, db: Session):
        self.db = db
        self.user_repo = UserRepository(db)
    
    def get_user(self, user_id: UUID) -> Optional[User]:
        """获取用户信息"""
        return self.user_repo.get_user_by_id(user_id)
    
    def update_user(
        self,
        user_id: UUID,
        username: Optional[str] = None,
        avatar_url: Optional[str] = None
    ) -> Optional[User]:
        """更新用户信息"""
        update_data = {}
        if username is not None:
            update_data["username"] = username
        if avatar_url is not None:
            update_data["avatar_url"] = avatar_url
        
        return self.user_repo.update_user(user_id, **update_data)
    
    def get_user_stats(self, user_id: UUID) -> Dict[str, Any]:
        """获取用户统计数据"""
        return self.user_repo.get_user_stats(user_id)
