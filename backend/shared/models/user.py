from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional
from uuid import UUID

class UserBase(BaseModel):
    username: str
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    """用户更新模型（不包含敏感信息）"""
    username: Optional[str] = None
    avatar_url: Optional[str] = None

class UserAPIKeysUpdate(BaseModel):
    """用户API密钥更新模型"""
    glm_api_key: Optional[str] = None
    tuzi_api_key: Optional[str] = None
    gemini_api_key: Optional[str] = None

class UserResponse(UserBase):
    id: UUID
    avatar: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime
    # 注意：响应中不包含API密钥，只返回是否已配置
    has_glm_api_key: bool = False
    has_tuzi_api_key: bool = False
    has_gemini_api_key: bool = False

    class Config:
        from_attributes = True
