from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from uuid import UUID
from datetime import datetime

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from shared.models.message import MessageCreate
from services.agent_service.src.services.message_service import MessageService
from services.agent_service.src.api.auth import get_current_user

router = APIRouter(prefix="/conversations/{conversation_id}/messages", tags=["消息"])

@router.get("", response_model=dict)
async def get_messages(
    conversation_id: UUID,
    page: int = Query(1, ge=1),
    pageSize: int = Query(50, ge=1, le=100),
    before: Optional[str] = Query(None, description="获取指定时间之前的消息，格式：YYYY-MM-DDTHH:MM:SS"),
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取消息列表"""
    service = MessageService(db)
    
    # 解析before参数
    before_datetime = None
    if before:
        try:
            before_datetime = datetime.fromisoformat(before.replace('Z', '+00:00'))
        except ValueError:
            raise HTTPException(status_code=400, detail="before参数格式错误，请使用ISO格式：YYYY-MM-DDTHH:MM:SS")
    
    messages, total = service.get_messages(
        conversation_id=conversation_id,
        user_id=current_user.id,
        page=page,
        page_size=pageSize,
        before=before_datetime
    )
    
    return {
        "code": 200,
        "data": {
            "page": page,
            "pageSize": pageSize,
            "total": total,
            "items": [
                {
                    "id": str(m.id),
                    "role": m.role,
                    "content": m.content,
                    "type": m.type,
                    "metadata": m.metadata,
                    "createdAt": m.created_at.isoformat()
                }
                for m in messages
            ]
        }
    }

@router.post("", response_model=dict)
async def create_message(
    conversation_id: UUID,
    message_data: MessageCreate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """创建消息"""
    service = MessageService(db)
    
    # 确保conversation_id与路径参数一致
    message_data.conversation_id = conversation_id
    
    message = service.create_message(
        conversation_id=conversation_id,
        user_id=current_user.id,
        message_data=message_data
    )
    
    if not message:
        raise HTTPException(status_code=404, detail="对话不存在")
    
    return {
        "code": 200,
        "message": "消息创建成功",
        "data": {
            "id": str(message.id),
            "role": message.role,
            "content": message.content,
            "type": message.type,
            "metadata": message.metadata,
            "createdAt": message.created_at.isoformat()
        }
    }

@router.get("/{message_id}", response_model=dict)
async def get_message(
    conversation_id: UUID,
    message_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取单条消息"""
    service = MessageService(db)
    message = service.get_message(
        message_id=message_id,
        conversation_id=conversation_id,
        user_id=current_user.id
    )
    
    if not message:
        raise HTTPException(status_code=404, detail="消息不存在")
    
    return {
        "code": 200,
        "data": {
            "id": str(message.id),
            "role": message.role,
            "content": message.content,
            "type": message.type,
            "metadata": message.metadata,
            "createdAt": message.created_at.isoformat()
        }
    }

@router.delete("/{message_id}", response_model=dict)
async def delete_message(
    conversation_id: UUID,
    message_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """删除消息"""
    service = MessageService(db)
    success = service.delete_message(
        message_id=message_id,
        conversation_id=conversation_id,
        user_id=current_user.id
    )
    
    if not success:
        raise HTTPException(status_code=404, detail="消息不存在")
    
    return {
        "code": 200,
        "message": "消息删除成功"
    }
