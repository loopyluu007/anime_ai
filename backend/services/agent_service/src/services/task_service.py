from sqlalchemy.orm import Session
from sqlalchemy import desc
from uuid import UUID
from typing import Tuple, List, Optional, Dict, Any
from datetime import datetime
import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.models.db_models import Task
from shared.models.task import TaskCreate, TaskStatus, TaskType
from services.agent_service.src.services.screenplay_service import ScreenplayService

class TaskService:
    """任务服务"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create_task(self, user_id: UUID, task_data: TaskCreate) -> Task:
        """创建任务"""
        task = Task(
            user_id=user_id,
            conversation_id=task_data.conversation_id,
            type=task_data.type.value,
            status=TaskStatus.PENDING.value,
            progress=0,
            params=task_data.params
        )
        
        self.db.add(task)
        self.db.commit()
        self.db.refresh(task)
        
        return task
    
    def get_tasks(
        self,
        user_id: UUID,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[Task], int]:
        """获取任务列表"""
        query = self.db.query(Task).filter(Task.user_id == user_id)
        
        total = query.count()
        
        tasks = query.order_by(desc(Task.created_at)).offset(
            (page - 1) * page_size
        ).limit(page_size).all()
        
        return tasks, total
    
    def get_task(self, task_id: UUID, user_id: UUID) -> Optional[Task]:
        """获取任务详情"""
        return self.db.query(Task).filter(
            Task.id == task_id,
            Task.user_id == user_id
        ).first()
    
    def update_task_status(
        self,
        task_id: UUID,
        status: TaskStatus,
        progress: Optional[int] = None,
        result: Optional[Dict[str, Any]] = None,
        error_message: Optional[str] = None
    ) -> Optional[Task]:
        """更新任务状态"""
        task = self.db.query(Task).filter(Task.id == task_id).first()
        if not task:
            return None
        
        task.status = status.value
        if progress is not None:
            task.progress = progress
        if result is not None:
            task.result = result
        if error_message is not None:
            task.error_message = error_message
        
        if status == TaskStatus.COMPLETED:
            task.completed_at = datetime.utcnow()
        elif status == TaskStatus.FAILED:
            task.completed_at = datetime.utcnow()
        
        task.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(task)
        
        return task
    
    def get_task_progress(self, task_id: UUID, user_id: UUID) -> Optional[Dict[str, Any]]:
        """获取任务进度"""
        task = self.get_task(task_id, user_id)
        if not task:
            return None
        
        return {
            "status": task.status,
            "progress": task.progress,
            "result": task.result,
            "errorMessage": task.error_message
        }
    
    def process_screenplay_task(self, task_id: UUID):
        """处理剧本任务（后台任务）"""
        import asyncio
        
        # 获取任务
        task = self.db.query(Task).filter(Task.id == task_id).first()
        if not task:
            return
        
        # 更新任务状态为处理中
        self.update_task_status(task_id, TaskStatus.PROCESSING, progress=10)
        
        try:
            # 从任务参数中提取信息
            params = task.params or {}
            prompt = params.get("prompt", "")
            user_images = params.get("user_images")
            scene_count = params.get("scene_count", 7)
            character_count = params.get("character_count", 2)
            
            if not prompt:
                raise ValueError("任务参数中缺少prompt")
            
            # 创建剧本服务并生成剧本草稿
            screenplay_service = ScreenplayService(self.db)
            
            # 使用asyncio运行异步方法
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            try:
                screenplay = loop.run_until_complete(
                    screenplay_service.create_draft(
                        user_id=task.user_id,
                        task_id=task_id,
                        prompt=prompt,
                        user_images=user_images,
                        scene_count=scene_count,
                        character_count=character_count
                    )
                )
                # 剧本生成成功，任务状态已在create_draft中更新为COMPLETED
            finally:
                loop.close()
                
        except Exception as e:
            # 更新任务状态为失败
            error_message = str(e)
            self.update_task_status(
                task_id,
                TaskStatus.FAILED,
                error_message=error_message
            )
            # 记录错误日志
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"处理剧本任务失败 (task_id={task_id}): {error_message}", exc_info=True)
