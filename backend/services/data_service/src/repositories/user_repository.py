"""用户数据访问层"""
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from shared.models.db_models import User, Conversation, Task, Message

class UserRepository:
    """用户数据访问"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_user_by_id(self, user_id: UUID) -> Optional[User]:
        """根据ID获取用户"""
        return self.db.query(User).filter(User.id == user_id).first()
    
    def update_user(self, user_id: UUID, **kwargs) -> Optional[User]:
        """更新用户信息"""
        user = self.get_user_by_id(user_id)
        if not user:
            return None
        
        for key, value in kwargs.items():
            if hasattr(user, key) and value is not None:
                setattr(user, key, value)
        
        user.updated_at = datetime.utcnow()
        self.db.commit()
        self.db.refresh(user)
        return user
    
    def get_user_stats(self, user_id: UUID) -> Dict[str, Any]:
        """获取用户统计数据（优化：使用聚合查询减少查询次数）"""
        from sqlalchemy import case
        
        user = self.get_user_by_id(user_id)
        if not user:
            return {}
        
        # 对话统计
        conversation_count = self.db.query(func.count(Conversation.id)).filter(
            Conversation.user_id == user_id
        ).scalar() or 0
        
        # 消息统计（通过JOIN优化）
        message_count = self.db.query(func.count(Message.id)).join(
            Conversation, Message.conversation_id == Conversation.id
        ).filter(Conversation.user_id == user_id).scalar() or 0
        
        # 任务统计（使用聚合查询一次性获取）
        task_stats = self.db.query(
            func.count(Task.id).label("task_count"),
            func.sum(case((Task.status == "completed", 1), else_=0)).label("completed_task_count"),
        ).filter(Task.user_id == user_id).first()
        
        task_count = task_stats.task_count or 0
        completed_task_count = task_stats.completed_task_count or 0
        
        # 最近7天活跃度
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        recent_conversations = self.db.query(func.count(Conversation.id)).filter(
            and_(
                Conversation.user_id == user_id,
                Conversation.last_accessed_at >= seven_days_ago
            )
        ).scalar() or 0
        
        return {
            "conversation_count": conversation_count,
            "message_count": message_count,
            "task_count": task_count,
            "completed_task_count": completed_task_count,
            "recent_activity": recent_conversations,
            "created_at": user.created_at.isoformat() if user.created_at else None
        }
