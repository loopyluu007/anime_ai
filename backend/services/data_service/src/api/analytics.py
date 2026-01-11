"""数据分析 API"""
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from uuid import UUID
from datetime import datetime
from typing import Optional

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from services.data_service.src.services.analytics_service import AnalyticsService
from services.agent_service.src.api.auth import get_current_user
from shared.utils.permissions import is_admin

router = APIRouter(prefix="/analytics", tags=["数据分析"])


@router.get("/overview", response_model=dict)
async def get_overview(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db),
    user_id: Optional[UUID] = Query(None, description="用户ID（可选，管理员可查看所有用户）")
):
    """获取系统概览统计"""
    # 普通用户只能查看自己的统计
    target_user_id = user_id if user_id else current_user.id
    
    # 管理员权限检查：如果指定了user_id且不是管理员，则无权查看其他用户统计
    if user_id and user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权查看其他用户统计"
        )
    
    service = AnalyticsService(db)
    stats = service.get_overview_stats(user_id=target_user_id)
    
    return {
        "code": 200,
        "data": stats
    }


@router.get("/tasks", response_model=dict)
async def get_task_analytics(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db),
    days: int = Query(30, ge=1, le=365, description="统计天数"),
    start_date: Optional[str] = Query(None, description="开始日期（ISO格式）"),
    end_date: Optional[str] = Query(None, description="结束日期（ISO格式）"),
    user_id: Optional[UUID] = Query(None, description="用户ID（可选）")
):
    """获取任务统计分析"""
    # 普通用户只能查看自己的统计
    target_user_id = user_id if user_id else current_user.id
    
    # 管理员权限检查：如果指定了user_id且不是管理员，则无权查看其他用户统计
    if user_id and user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权查看其他用户统计"
        )
    
    start_dt = None
    if start_date:
        try:
            start_dt = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="开始日期格式错误，请使用ISO格式"
            )
    
    end_dt = None
    if end_date:
        try:
            end_dt = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="结束日期格式错误，请使用ISO格式"
            )
    
    service = AnalyticsService(db)
    analytics = service.get_task_analytics(
        user_id=target_user_id,
        start_date=start_dt,
        end_date=end_dt,
        days=days
    )
    
    return {
        "code": 200,
        "data": analytics
    }


@router.get("/conversations", response_model=dict)
async def get_conversation_analytics(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db),
    days: int = Query(30, ge=1, le=365, description="统计天数"),
    user_id: Optional[UUID] = Query(None, description="用户ID（可选）")
):
    """获取对话统计分析"""
    # 普通用户只能查看自己的统计
    target_user_id = user_id if user_id else current_user.id
    
    # 管理员权限检查：如果指定了user_id且不是管理员，则无权查看其他用户统计
    if user_id and user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权查看其他用户统计"
        )
    
    service = AnalyticsService(db)
    analytics = service.get_conversation_analytics(
        user_id=target_user_id,
        days=days
    )
    
    return {
        "code": 200,
        "data": analytics
    }


@router.get("/media", response_model=dict)
async def get_media_analytics(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db),
    user_id: Optional[UUID] = Query(None, description="用户ID（可选）")
):
    """获取媒体文件统计分析"""
    # 普通用户只能查看自己的统计
    target_user_id = user_id if user_id else current_user.id
    
    # 管理员权限检查：如果指定了user_id且不是管理员，则无权查看其他用户统计
    if user_id and user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="无权查看其他用户统计"
        )
    
    service = AnalyticsService(db)
    analytics = service.get_media_analytics(user_id=target_user_id)
    
    return {
        "code": 200,
        "data": analytics
    }
