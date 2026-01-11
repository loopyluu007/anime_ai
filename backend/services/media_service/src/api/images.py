"""图片生成 API"""
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks, status
from sqlalchemy.orm import Session
from uuid import UUID

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from shared.models.media import ImageGenerateRequest
from services.media_service.src.services.image_service import ImageService
from services.agent_service.src.api.auth import get_current_user

router = APIRouter(prefix="/media/images", tags=["图片"])


async def process_image_generation(task_id: UUID):
    """处理图片生成的后台任务"""
    from shared.config.database import SessionLocal
    db = SessionLocal()
    service = ImageService(db)
    try:
        await service.generate_image(task_id)
    finally:
        await service.close()
        db.close()


@router.post("/generate", response_model=dict)
async def generate_image(
    request: ImageGenerateRequest,
    background_tasks: BackgroundTasks,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """生成图片（异步）"""
    service = ImageService(db)
    
    try:
        # 创建任务
        task = service.create_image_task(
            user_id=current_user.id,
            prompt=request.prompt,
            model=request.model,
            size=request.size,
            reference_images=request.reference_images
        )
        
        # 启动后台任务
        background_tasks.add_task(
            process_image_generation,
            task.id
        )
        
        return {
            "code": 200,
            "message": "图片生成任务已创建",
            "data": {
                "taskId": str(task.id),
                "status": task.status
            }
        }
    finally:
        await service.close()


@router.get("/{image_id}", response_model=dict)
async def get_image(
    image_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取生成的图片"""
    service = ImageService(db)
    
    try:
        media_file = service.get_media_file(image_id, current_user.id)
        
        if not media_file:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="图片不存在"
            )
        
        return {
            "code": 200,
            "data": {
                "id": str(media_file.id),
                "url": media_file.url,
                "status": "completed",
                "size": media_file.size,
                "width": media_file.width,
                "height": media_file.height,
                "createdAt": media_file.created_at.isoformat()
            }
        }
    finally:
        await service.close()
