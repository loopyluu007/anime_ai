"""媒体文件模型"""
from pydantic import BaseModel
from datetime import datetime
from typing import Optional, Dict, Any, List
from uuid import UUID
from enum import Enum

class MediaType(str, Enum):
    IMAGE = "image"
    VIDEO = "video"

class ImageGenerateRequest(BaseModel):
    """图片生成请求"""
    prompt: str
    model: str = "gemini-3-pro-image-preview-hd"
    size: str = "1024x1024"
    reference_images: Optional[List[str]] = None

class VideoGenerateRequest(BaseModel):
    """视频生成请求"""
    image_id: Optional[str] = None
    image_url: Optional[str] = None
    prompt: str
    model: str = "sora-1"
    seconds: str = "10"
    reference_images: Optional[List[str]] = None

class MediaFileResponse(BaseModel):
    """媒体文件响应"""
    id: UUID
    user_id: UUID
    type: str
    url: str
    status: Optional[str] = None
    size: Optional[int] = None
    width: Optional[int] = None
    height: Optional[int] = None
    duration: Optional[int] = None
    created_at: datetime
    
    class Config:
        from_attributes = True
