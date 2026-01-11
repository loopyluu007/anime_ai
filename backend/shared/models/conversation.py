from pydantic import BaseModel
from datetime import datetime
from typing import Optional
from uuid import UUID

class ConversationBase(BaseModel):
    title: str

class ConversationCreate(ConversationBase):
    pass

class ConversationResponse(ConversationBase):
    id: UUID
    user_id: UUID
    preview_text: Optional[str] = None
    message_count: int = 0
    is_pinned: bool = False
    last_accessed_at: datetime
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ConversationUpdate(BaseModel):
    title: Optional[str] = None
    is_pinned: Optional[bool] = None
