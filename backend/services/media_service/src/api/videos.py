"""视频生成 API"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from sqlalchemy.orm import Session
from uuid import UUID

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from shared.models.media import VideoGenerateRequest
from services.media_service.src.services.video_service import VideoService
from services.agent_service.src.api.auth import get_current_user

router = APIRouter(prefix="/media/videos", tags=["视频"])


async def process_video_generation(task_id: UUID):
    """处理视频生成的后台任务"""
    from shared.config.database import SessionLocal
    db = SessionLocal()
    service = VideoService(db)
    try:
        await service.generate_video(task_id)
    finally:
        await service.close()
        db.close()


@router.post("/generate", response_model=dict)
async def generate_video(
    request: VideoGenerateRequest,
    background_tasks: BackgroundTasks,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """生成视频（异步）"""
    service = VideoService(db)
    
    try:
        # 创建任务
        task = service.create_video_task(
            user_id=current_user.id,
            prompt=request.prompt,
            image_id=request.image_id,
            image_url=request.image_url,
            model=request.model,
            seconds=request.seconds,
            reference_images=request.reference_images
        )
        
        # 启动后台任务
        background_tasks.add_task(
            process_video_generation,
            task.id
        )
        
        return {
            "code": 200,
            "message": "视频生成任务已创建",
            "data": {
                "taskId": str(task.id),
                "status": task.status
            }
        }
    finally:
        await service.close()


@router.get("/{video_id}", response_model=dict)
async def get_video(
    video_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取生成的视频"""
    service = VideoService(db)
    
    try:
        media_file = service.get_media_file(video_id, current_user.id)
        
        if not media_file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="视频不存在"
            )
        
        return {
            "code": 200,
            "data": {
                "id": str(media_file.id),
                "url": media_file.url,
                "status": "completed",
                "duration": media_file.duration,
                "size": media_file.size,
                "createdAt": media_file.created_at.isoformat()
            }
        }
    finally:
        await service.close()
