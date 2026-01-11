from sqlalchemy.orm import Session
from sqlalchemy import desc
from uuid import UUID
from typing import Tuple, List, Optional
from shared.models.db_models import Conversation, Message
from shared.models.conversation import ConversationCreate, ConversationUpdate

class ConversationService:
    """对话服务"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def create_conversation(self, user_id: UUID, conversation_data: ConversationCreate) -> Conversation:
        """创建对话"""
        conversation = Conversation(
            user_id=user_id,
            title=conversation_data.title,
            message_count=0,
            is_pinned=False
        )
        
        self.db.add(conversation)
        self.db.commit()
        self.db.refresh(conversation)
        
        return conversation
    
    def get_conversations(
        self,
        user_id: UUID,
        page: int = 1,
        page_size: int = 20,
        pinned: Optional[bool] = None
    ) -> Tuple[List[Conversation], int]:
        """获取对话列表"""
        query = self.db.query(Conversation).filter(Conversation.user_id == user_id)
        
        if pinned is not None:
            query = query.filter(Conversation.is_pinned == pinned)
        
        total = query.count()
        
        conversations = query.order_by(
            desc(Conversation.is_pinned),
            desc(Conversation.updated_at)
        ).offset((page - 1) * page_size).limit(page_size).all()
        
        return conversations, total
    
    def get_conversation(self, conversation_id: UUID, user_id: UUID) -> Optional[Conversation]:
        """获取对话详情"""
        return self.db.query(Conversation).filter(
            Conversation.id == conversation_id,
            Conversation.user_id == user_id
        ).first()
    
    def update_conversation(
        self,
        conversation_id: UUID,
        user_id: UUID,
        conversation_data: ConversationUpdate
    ) -> Optional[Conversation]:
        """更新对话"""
        conversation = self.get_conversation(conversation_id, user_id)
        if not conversation:
            return None
        
        if conversation_data.title is not None:
            conversation.title = conversation_data.title
        if conversation_data.is_pinned is not None:
            conversation.is_pinned = conversation_data.is_pinned
        
        self.db.commit()
        self.db.refresh(conversation)
        
        return conversation
    
    def delete_conversation(self, conversation_id: UUID, user_id: UUID) -> bool:
        """删除对话"""
        conversation = self.get_conversation(conversation_id, user_id)
        if not conversation:
            return False
        
        self.db.delete(conversation)
        self.db.commit()
        
        return True
    
    def update_last_accessed(self, conversation_id: UUID):
        """更新最后访问时间"""
        conversation = self.db.query(Conversation).filter(
            Conversation.id == conversation_id
        ).first()
        
        if conversation:
            from datetime import datetime
            conversation.last_accessed_at = datetime.utcnow()
            self.db.commit()
