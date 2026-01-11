"""用户数据 API"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from uuid import UUID
from typing import Optional

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from services.data_service.src.services.user_service import UserService
from shared.utils.auth import get_current_user
from shared.models.user import UserAPIKeysUpdate

router = APIRouter(prefix="/users", tags=["用户数据"])


@router.get("/{user_id}", response_model=dict)
async def get_user(
    user_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户详细信息"""
    # 只能查看自己的信息
    if str(current_user.id) != str(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权访问其他用户信息"
        )
    
    service = UserService(db)
    user = service.get_user(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    return {
        "code": 200,
        "data": {
            "id": str(user.id),
            "username": user.username,
            "email": user.email,
            "avatar": user.avatar_url,
            "isActive": user.is_active,
            "createdAt": user.created_at.isoformat() if user.created_at else None,
            "updatedAt": user.updated_at.isoformat() if user.updated_at else None
        }
    }


@router.put("/{user_id}", response_model=dict)
async def update_user(
    user_id: UUID,
    username: Optional[str] = None,
    avatar_url: Optional[str] = None,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新用户信息"""
    # 只能更新自己的信息
    if str(current_user.id) != str(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权修改其他用户信息"
        )
    
    service = UserService(db)
    user = service.update_user(
        user_id=user_id,
        username=username,
        avatar_url=avatar_url
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    return {
        "code": 200,
        "message": "更新成功",
        "data": {
            "id": str(user.id),
            "username": user.username,
            "avatar": user.avatar_url,
            "updatedAt": user.updated_at.isoformat() if user.updated_at else None
        }
    }


@router.get("/{user_id}/stats", response_model=dict)
async def get_user_stats(
    user_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户统计数据"""
    # 只能查看自己的统计
    if str(current_user.id) != str(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权访问其他用户统计"
        )
    
    service = UserService(db)
    stats = service.get_user_stats(user_id)
    
    if not stats:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    return {
        "code": 200,
        "data": stats
    }


@router.put("/{user_id}/api-keys", response_model=dict)
async def update_user_api_keys(
    user_id: UUID,
    api_keys: UserAPIKeysUpdate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新用户API密钥"""
    # 只能更新自己的密钥
    if str(current_user.id) != str(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权修改其他用户信息"
        )
    
    service = UserService(db)
    user = service.update_user_api_keys(
        user_id=user_id,
        glm_api_key=api_keys.glm_api_key,
        tuzi_api_key=api_keys.tuzi_api_key,
        gemini_api_key=api_keys.gemini_api_key
    )
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    return {
        "code": 200,
        "message": "API密钥更新成功",
        "data": {
            "has_glm_api_key": user.glm_api_key is not None,
            "has_tuzi_api_key": user.tuzi_api_key is not None,
            "has_gemini_api_key": user.gemini_api_key is not None
        }
    }


@router.get("/{user_id}/api-keys/status", response_model=dict)
async def get_user_api_keys_status(
    user_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取用户API密钥配置状态（不返回实际密钥）"""
    if str(current_user.id) != str(user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权访问其他用户信息"
        )
    
    service = UserService(db)
    user = service.get_user(user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在"
        )
    
    return {
        "code": 200,
        "data": {
            "has_glm_api_key": user.glm_api_key is not None,
            "has_tuzi_api_key": user.tuzi_api_key is not None,
            "has_gemini_api_key": user.gemini_api_key is not None
        }
    }
