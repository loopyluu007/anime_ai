"""认证工具函数（可在所有服务中使用）"""
from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from jose import JWTError, jwt
from typing import Optional
from datetime import datetime, timedelta
import os

from shared.models.db_models import User
from shared.utils.exceptions import AuthenticationError
from shared.config.database import get_db

# JWT配置
SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_user_by_id(db: Session, user_id: str) -> Optional[User]:
    """根据ID获取用户（可在所有服务中使用）"""
    from uuid import UUID
    try:
        uuid_id = UUID(user_id)
        return db.query(User).filter(User.id == uuid_id).first()
    except (ValueError, TypeError):
        return None


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """创建访问令牌（可在所有服务中使用）"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
) -> User:
    """
    获取当前用户（可在所有服务中使用）
    
    这是一个通用的认证依赖函数，所有服务都可以使用它来验证JWT token并获取当前用户。
    """
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise AuthenticationError("Token 无效")
    except JWTError:
        raise AuthenticationError("Token 无效")
    
    user = get_user_by_id(db, user_id)
    if user is None:
        raise AuthenticationError("用户不存在")
    return user
