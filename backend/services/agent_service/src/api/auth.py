from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from jose import JWTError, jwt
from typing import Optional
import os

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from shared.models.user import UserCreate
from shared.utils.exceptions import AuthenticationError
from services.agent_service.src.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["认证"])

SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """创建访问令牌"""
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
):
    """获取当前用户"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise AuthenticationError("Token 无效")
    except JWTError:
        raise AuthenticationError("Token 无效")
    
    auth_service = AuthService(db)
    user = auth_service.get_user_by_id(user_id)
    if user is None:
        raise AuthenticationError("用户不存在")
    return user

@router.post("/register", response_model=dict)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """用户注册"""
    auth_service = AuthService(db)
    
    # 检查用户是否已存在
    if auth_service.get_user_by_email(user_data.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="邮箱已被注册"
        )
    
    try:
        # 创建用户
        user = auth_service.create_user(user_data)
        
        # 生成 Token
        access_token = create_access_token(data={"sub": str(user.id)})
        
        return {
            "code": 200,
            "message": "注册成功",
            "data": {
                "userId": str(user.id),
                "token": access_token,
                "refreshToken": access_token  # 简化实现，实际应单独生成
            }
        }
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/login", response_model=dict)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """用户登录"""
    auth_service = AuthService(db)
    user = auth_service.get_user_by_email(form_data.username)  # OAuth2 使用 username 字段传邮箱
    
    if not user or not auth_service.verify_password(form_data.password, user.password_hash):
        raise AuthenticationError("邮箱或密码错误")
    
    access_token = create_access_token(data={"sub": str(user.id)})
    
    return {
        "code": 200,
        "message": "登录成功",
        "data": {
            "userId": str(user.id),
            "token": access_token,
            "refreshToken": access_token,
            "expiresIn": ACCESS_TOKEN_EXPIRE_MINUTES * 60
        }
    }

@router.get("/me", response_model=dict)
async def get_me(current_user = Depends(get_current_user)):
    """获取当前用户信息"""
    return {
        "code": 200,
        "data": {
            "id": str(current_user.id),
            "username": current_user.username,
            "email": current_user.email,
            "avatar": current_user.avatar_url,
            "createdAt": current_user.created_at.isoformat()
        }
    }
