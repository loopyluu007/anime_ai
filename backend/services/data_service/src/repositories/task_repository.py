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
        """获取任务统计数据（优化：使用聚合查询）"""
        from sqlalchemy import case
        
        # 构建基础查询条件
        base_query = self.db.query(Task)
        
        if user_id:
            base_query = base_query.filter(Task.user_id == user_id)
        
        if start_date:
            base_query = base_query.filter(Task.created_at >= start_date)
        
        if end_date:
            base_query = base_query.filter(Task.created_at <= end_date)
        
        # 使用单次聚合查询获取所有统计信息
        stats_query = base_query.with_entities(
            func.count(Task.id).label("total_count"),
            func.sum(case((Task.status == "pending", 1), else_=0)).label("pending_count"),
            func.sum(case((Task.status == "processing", 1), else_=0)).label("processing_count"),
            func.sum(case((Task.status == "completed", 1), else_=0)).label("completed_count"),
            func.sum(case((Task.status == "failed", 1), else_=0)).label("failed_count"),
            func.sum(case((Task.status == "cancelled", 1), else_=0)).label("cancelled_count"),
            func.sum(case((Task.type == "screenplay", 1), else_=0)).label("screenplay_count"),
            func.sum(case((Task.type == "image", 1), else_=0)).label("image_count"),
            func.sum(case((Task.type == "video", 1), else_=0)).label("video_count"),
        )
        
        stats = stats_query.first()
        
        total_count = stats.total_count or 0
        
        status_counts = {
            "pending": stats.pending_count or 0,
            "processing": stats.processing_count or 0,
            "completed": stats.completed_count or 0,
            "failed": stats.failed_count or 0,
            "cancelled": stats.cancelled_count or 0,
        }
        
        type_counts = {
            "screenplay": stats.screenplay_count or 0,
            "image": stats.image_count or 0,
            "video": stats.video_count or 0,
        }
        
        # 平均处理时间（仅已完成的任务）- 使用聚合查询
        avg_duration_query = base_query.filter(
            and_(
                Task.status == "completed",
                Task.completed_at.isnot(None),
                Task.created_at.isnot(None)
            )
        ).with_entities(
            func.avg(
                func.extract('epoch', Task.completed_at - Task.created_at)
            ).label("avg_duration")
        )
        
        avg_duration_result = avg_duration_query.scalar()
        avg_duration = round(avg_duration_result, 2) if avg_duration_result else None
        
        # 成功率
        success_rate = 0
        if total_count > 0:
            success_count = status_counts.get("completed", 0)
            success_rate = round((success_count / total_count) * 100, 2)
        
        return {
            "total_count": total_count,
            "status_counts": status_counts,
            "type_counts": type_counts,
            "avg_duration_seconds": avg_duration,
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
