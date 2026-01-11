"""图片生成服务"""
from sqlalchemy.orm import Session
from uuid import UUID
from typing import Optional, Dict, Any
from datetime import datetime
import asyncio

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.models.db_models import Task, MediaFile
from shared.models.task import TaskStatus, TaskType
from services.media_service.src.clients.gemini_client import GeminiClient


class ImageService:
    """图片生成服务"""
    
    def __init__(self, db: Session):
        self.db = db
        self.gemini_client = GeminiClient()
    
    def create_image_task(
        self,
        user_id: UUID,
        prompt: str,
        model: str = "gemini-3-pro-image-preview-hd",
        size: str = "1024x1024",
        reference_images: Optional[list] = None
    ) -> Task:
        """创建图片生成任务"""
        task = Task(
            user_id=user_id,
            type=TaskType.IMAGE.value,
            status=TaskStatus.PENDING.value,
            progress=0,
            params={
                "prompt": prompt,
                "model": model,
                "size": size,
                "reference_images": reference_images or []
            }
        )
        
        self.db.add(task)
        self.db.commit()
        self.db.refresh(task)
        
        return task
    
    async def generate_image(self, task_id: UUID) -> Optional[MediaFile]:
        """生成图片（异步）"""
        task = self.db.query(Task).filter(Task.id == task_id).first()
        if not task:
            return None
        
        try:
            # 更新任务状态
            task.status = TaskStatus.PROCESSING.value
            task.progress = 10
            self.db.commit()
            
            params = task.params or {}
            prompt = params.get("prompt")
            model = params.get("model", "gemini-3-pro-image-preview-hd")
            size = params.get("size", "1024x1024")
            reference_images = params.get("reference_images", [])
            
            # 调用 Gemini 客户端生成图片
            response = await self.gemini_client.generate_image(
                prompt=prompt,
                model=model,
                size=size,
                reference_images=reference_images
            )
            
            # 解析响应
            image_data = response.get("data", [])
            if not image_data:
                raise ValueError("图片生成失败：响应中没有数据")
            
            image_info = image_data[0]
            image_url = image_info.get("url")
            
            if not image_url:
                raise ValueError("图片生成失败：响应中没有URL")
            
            # 创建媒体文件记录
            media_file = MediaFile(
                user_id=task.user_id,
                type="image",
                storage_path=image_url,  # 暂时使用URL作为路径
                url=image_url,
                metadata={
                    "prompt": prompt,
                    "model": model,
                    "size": size,
                    "task_id": str(task_id)
                }
            )
            
            self.db.add(media_file)
            
            # 更新任务状态
            task.status = TaskStatus.COMPLETED.value
            task.progress = 100
            task.result = {
                "media_file_id": str(media_file.id),
                "url": image_url
            }
            task.completed_at = datetime.utcnow()
            
            self.db.commit()
            self.db.refresh(media_file)
            
            return media_file
            
        except Exception as e:
            # 更新任务状态为失败
            task.status = TaskStatus.FAILED.value
            task.error_message = str(e)
            task.completed_at = datetime.utcnow()
            self.db.commit()
            raise
    
    def get_media_file(self, media_file_id: UUID, user_id: UUID) -> Optional[MediaFile]:
        """获取媒体文件"""
        return self.db.query(MediaFile).filter(
            MediaFile.id == media_file_id,
            MediaFile.user_id == user_id
        ).first()
    
    async def close(self):
        """关闭客户端"""
        await self.gemini_client.close()
