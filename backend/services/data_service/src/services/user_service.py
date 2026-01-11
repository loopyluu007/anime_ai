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
    
    def update_user_api_keys(
        self,
        user_id: UUID,
        glm_api_key: Optional[str] = None,
        tuzi_api_key: Optional[str] = None,
        gemini_api_key: Optional[str] = None
    ) -> Optional[User]:
        """更新用户API密钥"""
        update_data = {}
        
        if glm_api_key is not None:
            # 空字符串表示清空密钥
            update_data["glm_api_key"] = glm_api_key if glm_api_key else None
        
        if tuzi_api_key is not None:
            update_data["tuzi_api_key"] = tuzi_api_key if tuzi_api_key else None
        
        if gemini_api_key is not None:
            update_data["gemini_api_key"] = gemini_api_key if gemini_api_key else None
        
        return self.user_repo.update_user(user_id, **update_data)
    
    def get_user_api_key(self, user_id: UUID, key_type: str) -> Optional[str]:
        """获取用户API密钥"""
        user = self.user_repo.get_user_by_id(user_id)
        if not user:
            return None
        
        if key_type == "glm":
            return user.glm_api_key
        elif key_type == "tuzi":
            return user.tuzi_api_key
        elif key_type == "gemini":
            return user.gemini_api_key
        
        return None
    
    def get_user_stats(self, user_id: UUID) -> Dict[str, Any]:
        """获取用户统计数据"""
        return self.user_repo.get_user_stats(user_id)
