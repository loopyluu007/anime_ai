"""视频生成服务"""
from sqlalchemy.orm import Session
from uuid import UUID
from typing import Optional, Dict, Any, List
from datetime import datetime
import asyncio

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.models.db_models import Task, MediaFile
from shared.models.task import TaskStatus, TaskType
from services.media_service.src.clients.tuzi_client import TuziClient
from services.data_service.src.services.user_service import UserService


class VideoService:
    """视频生成服务"""
    
    def __init__(self, db: Session):
        self.db = db
        self.user_service = UserService(db)
    
    def create_video_task(
        self,
        user_id: UUID,
        prompt: str,
        image_id: Optional[str] = None,
        image_url: Optional[str] = None,
        model: str = "sora-1",
        seconds: str = "10",
        reference_images: Optional[List[str]] = None
    ) -> Task:
        """创建视频生成任务"""
        task = Task(
            user_id=user_id,
            type=TaskType.VIDEO.value,
            status=TaskStatus.PENDING.value,
            progress=0,
            params={
                "prompt": prompt,
                "image_id": image_id,
                "image_url": image_url,
                "model": model,
                "seconds": seconds,
                "reference_images": reference_images or []
            }
        )
        
        self.db.add(task)
        self.db.commit()
        self.db.refresh(task)
        
        return task
    
    async def generate_video(self, task_id: UUID) -> Optional[MediaFile]:
        """生成视频（异步）"""
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
            model = params.get("model", "sora-1")
            seconds = params.get("seconds", "10")
            image_url = params.get("image_url")
            reference_images = params.get("reference_images", [])
            
            # 如果有 image_id，从数据库获取 URL
            image_id = params.get("image_id")
            if image_id and not image_url:
                media_file = self.db.query(MediaFile).filter(
                    MediaFile.id == UUID(image_id),
                    MediaFile.user_id == task.user_id
                ).first()
                if media_file:
                    image_url = media_file.url
            
            # 获取用户的Tuzi API密钥
            tuzi_api_key = self.user_service.get_user_api_key(task.user_id, "tuzi")
            if not tuzi_api_key:
                raise ValueError("用户未配置Tuzi API密钥，请先在设置中配置")
            
            # 使用用户密钥创建客户端
            tuzi_client = TuziClient(api_key=tuzi_api_key)
            
            try:
                # 调用 Tuzi 客户端生成视频
                response = await tuzi_client.generate_video(
                    prompt=prompt,
                    image_url=image_url,
                    seconds=seconds,
                    model=model,
                    reference_images=reference_images
                )
                
                # 解析响应
                video_task_id = response.get("task_id") or response.get("id")
                if not video_task_id:
                    raise ValueError("视频生成失败：响应中没有任务ID")
                
                # 轮询视频生成状态
                video_result = await tuzi_client.wait_for_video(
                    video_task_id,
                    max_wait_time=300,
                    poll_interval=5
                )
            finally:
                await tuzi_client.close()
            
            video_url = video_result.get("url") or video_result.get("video_url")
            if not video_url:
                raise ValueError("视频生成失败：响应中没有URL")
            
            # 创建媒体文件记录
            media_file = MediaFile(
                user_id=task.user_id,
                type="video",
                storage_path=video_url,  # 暂时使用URL作为路径
                url=video_url,
                duration=int(seconds),
                metadata={
                    "prompt": prompt,
                    "model": model,
                    "seconds": seconds,
                    "task_id": str(task_id),
                    "video_task_id": video_task_id
                }
            )
            
            self.db.add(media_file)
            
            # 更新任务状态
            task.status = TaskStatus.COMPLETED.value
            task.progress = 100
            task.result = {
                "media_file_id": str(media_file.id),
                "url": video_url
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
    
