"""任务数据访问层"""
from sqlalchemy.orm import Session
from sqlalchemy import func, and_, case
from uuid import UUID
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
from shared.models.db_models import Task

class TaskRepository:
    """任务数据访问"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_task_stats(
        self,
        user_id: Optional[UUID] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None
    ) -> Dict[str, Any]:
        """获取任务统计数据"""
        query = self.db.query(Task)
        
        if user_id:
            query = query.filter(Task.user_id == user_id)
        
        if start_date:
            query = query.filter(Task.created_at >= start_date)
        
        if end_date:
            query = query.filter(Task.created_at <= end_date)
        
        total_count = query.count()
        
        # 按状态统计
        status_counts = {}
        for status in ["pending", "processing", "completed", "failed", "cancelled"]:
            count = query.filter(Task.status == status).count()
            status_counts[status] = count
        
        # 按类型统计
        type_counts = {}
        for task_type in ["screenplay", "image", "video"]:
            count = query.filter(Task.type == task_type).count()
            type_counts[task_type] = count
        
        # 平均处理时间（仅已完成的任务）
        completed_tasks = query.filter(
            and_(
                Task.status == "completed",
                Task.completed_at.isnot(None)
            )
        ).all()
        
        avg_duration = None
        if completed_tasks:
            durations = []
            for task in completed_tasks:
                if task.completed_at and task.created_at:
                    duration = (task.completed_at - task.created_at).total_seconds()
                    durations.append(duration)
            
            if durations:
                avg_duration = sum(durations) / len(durations)
        
        # 成功率
        success_rate = 0
        if total_count > 0:
            success_count = status_counts.get("completed", 0)
            success_rate = round((success_count / total_count) * 100, 2)
        
        return {
            "total_count": total_count,
            "status_counts": status_counts,
            "type_counts": type_counts,
            "avg_duration_seconds": round(avg_duration, 2) if avg_duration else None,
            "success_rate": success_rate
        }
    
    def get_task_trend(
        self,
        user_id: Optional[UUID] = None,
        days: int = 30
    ) -> List[Dict[str, Any]]:
        """获取任务趋势数据"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        query = self.db.query(
            func.date(Task.created_at).label("date"),
            func.count(Task.id).label("count"),
            func.sum(
                case((Task.status == "completed", 1), else_=0)
            ).label("completed_count")
        ).filter(
            Task.created_at >= start_date
        )
        
        if user_id:
            query = query.filter(Task.user_id == user_id)
        
        results = query.group_by(
            func.date(Task.created_at)
        ).order_by(
            func.date(Task.created_at)
        ).all()
        
        return [
            {
                "date": result.date if isinstance(result.date, str) else (result.date.isoformat() if result.date else None),
                "total": result.count,
                "completed": result.completed_count or 0
            }
            for result in results
        ]
