"""对话数据访问层"""
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
from shared.models.db_models import Conversation, Message, Task

class ConversationRepository:
    """对话数据访问"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_conversation_stats(
        self,
        user_id: Optional[UUID] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """获取对话统计数据"""
        query = self.db.query(Conversation)
        
        if user_id:
            query = query.filter(Conversation.user_id == user_id)
        
        if start_date:
            query = query.filter(Conversation.created_at >= start_date)
        
        if end_date:
            query = query.filter(Conversation.created_at <= end_date)
        
        total_count = query.count()
        
        # 平均消息数
        avg_messages = self.db.query(func.avg(Conversation.message_count)).filter(
            Conversation.user_id == user_id if user_id else True
        ).scalar() or 0
        
        # 置顶对话数
        pinned_count = query.filter(Conversation.is_pinned == True).count()
        
        # 最近7天创建的对话
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        recent_count = query.filter(
            Conversation.created_at >= seven_days_ago
        ).count()
        
        return {
            "total_count": total_count,
            "avg_messages": round(float(avg_messages), 2) if avg_messages else 0,
            "pinned_count": pinned_count,
            "recent_count": recent_count
        }
    
    def get_conversation_trend(
        self,
        user_id: Optional[UUID] = None,
        days: int = 30
    ) -> List[Dict[str, Any]]:
        """获取对话趋势数据"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        query = self.db.query(
            func.date(Conversation.created_at).label("date"),
            func.count(Conversation.id).label("count")
        ).filter(
            Conversation.created_at >= start_date
        )
        
        if user_id:
            query = query.filter(Conversation.user_id == user_id)
        
        results = query.group_by(
            func.date(Conversation.created_at)
        ).order_by(
            func.date(Conversation.created_at)
        ).all()
        
        return [
            {
                "date": result.date.isoformat() if result.date else None,
                "count": result.count
            }
            for result in results
        ]
