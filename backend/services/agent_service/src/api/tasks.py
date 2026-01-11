from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from uuid import UUID

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from shared.models.task import TaskCreate
from services.agent_service.src.services.task_service import TaskService
from services.agent_service.src.api.auth import get_current_user

router = APIRouter(prefix="/tasks", tags=["任务"])

@router.post("", response_model=dict)
async def create_task(
    task_data: TaskCreate,
    background_tasks: BackgroundTasks,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """创建任务"""
    service = TaskService(db)
    task = service.create_task(current_user.id, task_data)
    
    # 如果是剧本生成任务，启动后台处理
    if task_data.type.value == "screenplay":
        background_tasks.add_task(
            service.process_screenplay_task,
            task.id
        )
    
    return {
        "code": 200,
        "message": "任务创建成功",
        "data": {
            "id": str(task.id),
            "type": task.type,
            "status": task.status,
            "progress": task.progress,
            "createdAt": task.created_at.isoformat()
        }
    }

@router.get("", response_model=dict)
async def get_tasks(
    page: int = 1,
    pageSize: int = 20,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取任务列表"""
    service = TaskService(db)
    tasks, total = service.get_tasks(
        user_id=current_user.id,
        page=page,
        page_size=pageSize
    )
    
    return {
        "code": 200,
        "data": {
            "page": page,
            "pageSize": pageSize,
            "total": total,
            "items": [
                {
                    "id": str(t.id),
                    "type": t.type,
                    "status": t.status,
                    "progress": t.progress,
                    "createdAt": t.created_at.isoformat()
                }
                for t in tasks
            ]
        }
    }

@router.get("/{task_id}", response_model=dict)
async def get_task(
    task_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取任务详情"""
    service = TaskService(db)
    task = service.get_task(task_id, current_user.id)
    
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")
    
    return {
        "code": 200,
        "data": {
            "id": str(task.id),
            "type": task.type,
            "status": task.status,
            "progress": task.progress,
            "result": task.result,
            "errorMessage": task.error_message,
            "createdAt": task.created_at.isoformat(),
            "updatedAt": task.updated_at.isoformat()
        }
    }

@router.get("/{task_id}/progress", response_model=dict)
async def get_task_progress(
    task_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取任务进度"""
    service = TaskService(db)
    progress = service.get_task_progress(task_id, current_user.id)
    
    if not progress:
        raise HTTPException(status_code=404, detail="任务不存在")
    
    return {
        "code": 200,
        "data": progress
    }
