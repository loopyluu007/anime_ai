from sqlalchemy.orm import Session
from sqlalchemy import desc, and_
from uuid import UUID
from typing import Tuple, List, Optional
from datetime import datetime
from shared.models.db_models import Message, Conversation
from shared.models.message import MessageCreate

class MessageService:
    """消息服务"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_messages(
        self,
        conversation_id: UUID,
        user_id: UUID,
        page: int = 1,
        page_size: int = 50,
        before: Optional[datetime] = None
    ) -> Tuple[List[Message], int]:
        """获取消息列表"""
        # 首先验证对话是否存在且属于该用户
        conversation = self.db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id
        ).first()
        
        if not conversation:
            return [], 0
        
        # 构建查询
        query = self.db.query(Message).filter(
            Message.conversation_id == conversation_id
        )
        
        # 如果指定了before参数，筛选指定时间之前的消息
        if before:
            query = query.filter(Message.created_at < before)
        
        # 获取总数
        total = query.count()
        
        # 按创建时间倒序排列（最新的在前）
        messages = query.order_by(
            desc(Message.created_at)
        ).offset((page - 1) * page_size).limit(page_size).all()
        
        # 更新对话的最后访问时间
        conversation.last_accessed_at = datetime.utcnow()
        self.db.commit()
        
        return messages, total
    
    def create_message(
        self,
        conversation_id: UUID,
        user_id: UUID,
        message_data: MessageCreate
    ) -> Optional[Message]:
        """创建消息"""
        # 验证对话是否存在且属于该用户
        conversation = self.db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id
        ).first()
        
        if not conversation:
            return None
        
        # 创建消息
        message = Message(
            conversation_id=conversation_id,
            role=message_data.role.value,
            content=message_data.content,
            type=message_data.type.value,
            metadata=message_data.metadata
        )
        
        self.db.add(message)
        
        # 更新对话的消息计数和最后访问时间
        conversation.message_count += 1
        conversation.last_accessed_at = datetime.utcnow()
        conversation.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(message)
        
        return message
    
    def get_message(
        self,
        message_id: UUID,
        conversation_id: UUID,
        user_id: UUID
    ) -> Optional[Message]:
        """获取单条消息"""
        # 验证对话是否存在且属于该用户
        conversation = self.db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id
        ).first()
        
        if not conversation:
            return None
        
        # 查询消息
        message = self.db.query(Message).filter(
            Message.id == message_id,
            Message.conversation_id == conversation_id
        ).first()
        
        return message
    
    def delete_message(
        self,
        message_id: UUID,
        conversation_id: UUID,
        user_id: UUID
    ) -> bool:
        """删除消息"""
        message = self.get_message(message_id, conversation_id, user_id)
        if not message:
            return False
        
        # 获取对话以更新消息计数
        conversation = self.db.query(Conversation).filter(
            Conversation.id == conversation_id
        ).first()
        
        if conversation and conversation.message_count > 0:
            conversation.message_count -= 1
            conversation.updated_at = datetime.utcnow()
        
        self.db.delete(message)
        self.db.commit()
        
        return True
