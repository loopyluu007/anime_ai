from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from uuid import UUID
from enum import Enum

class SceneStatus(str, Enum):
    PENDING = "pending"
    GENERATING = "generating"
    COMPLETED = "completed"
    FAILED = "failed"

class SceneBase(BaseModel):
    scene_id: int
    narration: str
    image_prompt: str
    video_prompt: str
    character_description: Optional[str] = None

class SceneResponse(SceneBase):
    id: UUID
    screenplay_id: UUID
    image_url: Optional[str] = None
    video_url: Optional[str] = None
    status: SceneStatus
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class CharacterSheetBase(BaseModel):
    name: str
    description: Optional[str] = None

class CharacterSheetResponse(CharacterSheetBase):
    id: UUID
    screenplay_id: UUID
    combined_view_url: Optional[str] = None
    front_view_url: Optional[str] = None
    side_view_url: Optional[str] = None
    back_view_url: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

class ScreenplayStatus(str, Enum):
    DRAFT = "draft"
    CONFIRMED = "confirmed"
    GENERATING = "generating"
    COMPLETED = "completed"
    FAILED = "failed"

class ScreenplayBase(BaseModel):
    title: str

class ScreenplayDraft(BaseModel):
    """生成剧本草稿请求"""
    task_id: UUID = Field(..., alias="taskId")
    prompt: str
    user_images: Optional[List[str]] = Field(None, alias="userImages")
    scene_count: int = Field(7, alias="sceneCount")
    character_count: int = Field(2, alias="characterCount")
    
    class Config:
        populate_by_name = True

class ScreenplayConfirm(BaseModel):
    """确认剧本请求"""
    feedback: Optional[str] = None

class ScreenplayUpdate(BaseModel):
    """更新剧本请求"""
    title: Optional[str] = None

class ScreenplayResponse(ScreenplayBase):
    id: UUID
    task_id: UUID
    user_id: UUID
    status: ScreenplayStatus
    scenes: List[SceneResponse] = []
    character_sheets: List[CharacterSheetResponse] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
