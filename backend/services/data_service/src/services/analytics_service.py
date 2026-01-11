"""数据分析服务"""
from sqlalchemy.orm import Session
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
from services.data_service.src.repositories.conversation_repository import ConversationRepository
from services.data_service.src.repositories.task_repository import TaskRepository
from services.data_service.src.repositories.user_repository import UserRepository
from shared.models.db_models import User, MediaFile
from sqlalchemy import func

class AnalyticsService:
    """数据分析服务"""
    
    def __init__(self, db: Session):
        self.db = db
        self.conversation_repo = ConversationRepository(db)
        self.task_repo = TaskRepository(db)
        self.user_repo = UserRepository(db)
    
    def get_overview_stats(
        self,
        user_id: Optional[UUID] = None
    ) -> Dict[str, Any]:
        """获取系统概览统计"""
        # 用户统计
        user_count = self.db.query(func.count(User.id)).scalar() or 0
        
        # 对话统计
        conversation_stats = self.conversation_repo.get_conversation_stats(user_id=user_id)
        
        # 任务统计
        task_stats = self.task_repo.get_task_stats(user_id=user_id)
        
        # 媒体文件统计
        media_query = self.db.query(MediaFile)
        if user_id:
            media_query = media_query.filter(MediaFile.user_id == user_id)
        
        media_count = media_query.count()
        total_media_size = media_query.with_entities(
            func.sum(MediaFile.size)
        ).scalar() or 0
        
        return {
            "user_count": user_count if not user_id else 1,
            "conversation": conversation_stats,
            "task": task_stats,
            "media": {
                "total_count": media_count,
                "total_size_bytes": total_media_size,
                "total_size_mb": round(total_media_size / (1024 * 1024), 2) if total_media_size else 0
            }
        }
    
    def get_task_analytics(
        self,
        user_id: Optional[UUID] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        days: int = 30
    ) -> Dict[str, Any]:
        """获取任务统计分析"""
        if not start_date:
            start_date = datetime.utcnow() - timedelta(days=days)
        
        stats = self.task_repo.get_task_stats(
            user_id=user_id,
            start_date=start_date,
            end_date=end_date
        )
        
        trend = self.task_repo.get_task_trend(
            user_id=user_id,
            days=days
        )
        
        return {
            "stats": stats,
            "trend": trend
        }
    
    def get_conversation_analytics(
        self,
        user_id: Optional[UUID] = None,
        days: int = 30
    ) -> Dict[str, Any]:
        """获取对话统计分析"""
        stats = self.conversation_repo.get_conversation_stats(user_id=user_id)
        trend = self.conversation_repo.get_conversation_trend(user_id=user_id, days=days)
        
        return {
            "stats": stats,
            "trend": trend
        }
    
    def get_media_analytics(
        self,
        user_id: Optional[UUID] = None
    ) -> Dict[str, Any]:
        """获取媒体文件统计分析"""
        query = self.db.query(MediaFile)
        if user_id:
            query = query.filter(MediaFile.user_id == user_id)
        
        # 按类型统计
        image_count = query.filter(MediaFile.type == "image").count()
        video_count = query.filter(MediaFile.type == "video").count()
        
        # 按类型统计大小
        image_size = query.filter(MediaFile.type == "image").with_entities(
            func.sum(MediaFile.size)
        ).scalar() or 0
        
        video_size = query.filter(MediaFile.type == "video").with_entities(
            func.sum(MediaFile.size)
        ).scalar() or 0
        
        # 最近7天上传的文件
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        recent_count = query.filter(
            MediaFile.created_at >= seven_days_ago
        ).count()
        
        return {
            "image": {
                "count": image_count,
                "total_size_bytes": image_size,
                "total_size_mb": round(image_size / (1024 * 1024), 2) if image_size else 0
            },
            "video": {
                "count": video_count,
                "total_size_bytes": video_size,
                "total_size_mb": round(video_size / (1024 * 1024), 2) if video_size else 0
            },
            "recent_count": recent_count,
            "total_count": image_count + video_count
        }
