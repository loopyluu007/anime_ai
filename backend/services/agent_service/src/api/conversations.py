from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from uuid import UUID

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from shared.models.conversation import ConversationCreate, ConversationUpdate
from services.agent_service.src.services.conversation_service import ConversationService
from shared.utils.auth import get_current_user

router = APIRouter(prefix="/conversations", tags=["对话"])

@router.post("", response_model=dict)
async def create_conversation(
    conversation_data: ConversationCreate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """创建对话"""
    service = ConversationService(db)
    conversation = service.create_conversation(current_user.id, conversation_data)
    
    return {
        "code": 200,
        "message": "创建成功",
        "data": {
            "id": str(conversation.id),
            "title": conversation.title,
            "messageCount": conversation.message_count,
            "isPinned": conversation.is_pinned,
            "createdAt": conversation.created_at.isoformat()
        }
    }

@router.get("", response_model=dict)
async def get_conversations(
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=100),
    pinned: Optional[bool] = None,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取对话列表"""
    service = ConversationService(db)
    conversations, total = service.get_conversations(
        user_id=current_user.id,
        page=page,
        page_size=pageSize,
        pinned=pinned
    )
    
    return {
        "code": 200,
        "data": {
            "page": page,
            "pageSize": pageSize,
            "total": total,
            "items": [
                {
                    "id": str(c.id),
                    "title": c.title,
                    "previewText": c.preview_text,
                    "messageCount": c.message_count,
                    "isPinned": c.is_pinned,
                    "lastAccessedAt": c.last_accessed_at.isoformat(),
                    "createdAt": c.created_at.isoformat()
                }
                for c in conversations
            ]
        }
    }

@router.get("/{conversation_id}", response_model=dict)
async def get_conversation(
    conversation_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取对话详情"""
    service = ConversationService(db)
    conversation = service.get_conversation(conversation_id, current_user.id)
    
    if not conversation:
        raise HTTPException(status_code=404, detail="对话不存在")
    
    return {
        "code": 200,
        "data": {
            "id": str(conversation.id),
            "title": conversation.title,
            "messageCount": conversation.message_count,
            "isPinned": conversation.is_pinned,
            "createdAt": conversation.created_at.isoformat(),
            "updatedAt": conversation.updated_at.isoformat()
        }
    }

@router.put("/{conversation_id}", response_model=dict)
async def update_conversation(
    conversation_id: UUID,
    conversation_data: ConversationUpdate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新对话"""
    service = ConversationService(db)
    conversation = service.update_conversation(
        conversation_id, current_user.id, conversation_data
    )
    
    if not conversation:
        raise HTTPException(status_code=404, detail="对话不存在")
    
    return {
        "code": 200,
        "message": "更新成功",
        "data": {
            "id": str(conversation.id),
            "title": conversation.title,
            "isPinned": conversation.is_pinned
        }
    }

@router.delete("/{conversation_id}", response_model=dict)
async def delete_conversation(
    conversation_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除对话"""
    service = ConversationService(db)
    success = service.delete_conversation(conversation_id, current_user.id)
    
    if not success:
        raise HTTPException(status_code=404, detail="对话不存在")
    
    return {
        "code": 200,
        "message": "删除成功"
    }
