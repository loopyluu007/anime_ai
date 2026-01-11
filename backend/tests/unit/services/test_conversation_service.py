"""对话服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from uuid import UUID, uuid4
from shared.models.conversation import ConversationCreate, ConversationUpdate
from services.agent_service.src.services.conversation_service import ConversationService
from shared.models.db_models import Conversation


@pytest.mark.unit
class TestConversationService:
    """对话服务测试类"""
    
    def test_create_conversation_success(self, db_session: Session, test_user):
        """测试成功创建对话"""
        service = ConversationService(db_session)
        conversation_data = ConversationCreate(title="测试对话")
        
        conversation = service.create_conversation(test_user.id, conversation_data)
        
        assert conversation is not None
        assert conversation.title == "测试对话"
        assert conversation.user_id == test_user.id
        assert conversation.message_count == 0
        assert conversation.is_pinned is False
        assert conversation.id is not None
    
    def test_get_conversations_empty(self, db_session: Session, test_user):
        """测试获取空对话列表"""
        service = ConversationService(db_session)
        conversations, total = service.get_conversations(test_user.id)
        
        assert conversations == []
        assert total == 0
    
    def test_get_conversations_with_data(self, db_session: Session, test_user):
        """测试获取对话列表（有数据）"""
        service = ConversationService(db_session)
        
        # 创建多个对话
        for i in range(5):
            conversation_data = ConversationCreate(title=f"对话{i+1}")
            service.create_conversation(test_user.id, conversation_data)
        
        conversations, total = service.get_conversations(test_user.id)
        
        assert len(conversations) == 5
        assert total == 5
        assert all(c.user_id == test_user.id for c in conversations)
    
    def test_get_conversations_pagination(self, db_session: Session, test_user):
        """测试对话列表分页"""
        service = ConversationService(db_session)
        
        # 创建10个对话
        for i in range(10):
            conversation_data = ConversationCreate(title=f"对话{i+1}")
            service.create_conversation(test_user.id, conversation_data)
        
        # 第一页
        conversations, total = service.get_conversations(test_user.id, page=1, page_size=5)
        assert len(conversations) == 5
        assert total == 10
        
        # 第二页
        conversations, total = service.get_conversations(test_user.id, page=2, page_size=5)
        assert len(conversations) == 5
        assert total == 10
    
    def test_get_conversations_filter_pinned(self, db_session: Session, test_user):
        """测试按置顶状态筛选对话"""
        service = ConversationService(db_session)
        
        # 创建置顶和非置顶对话
        pinned_data = ConversationCreate(title="置顶对话")
        pinned = service.create_conversation(test_user.id, pinned_data)
        service.update_conversation(pinned.id, test_user.id, ConversationUpdate(is_pinned=True))
        
        normal_data = ConversationCreate(title="普通对话")
        service.create_conversation(test_user.id, normal_data)
        
        # 获取置顶对话
        conversations, total = service.get_conversations(test_user.id, pinned=True)
        assert total == 1
        assert conversations[0].is_pinned is True
        
        # 获取非置顶对话
        conversations, total = service.get_conversations(test_user.id, pinned=False)
        assert total == 1
        assert conversations[0].is_pinned is False
    
    def test_get_conversation_success(self, db_session: Session, test_user):
        """测试成功获取对话详情"""
        service = ConversationService(db_session)
        conversation_data = ConversationCreate(title="测试对话")
        created = service.create_conversation(test_user.id, conversation_data)
        
        conversation = service.get_conversation(created.id, test_user.id)
        
        assert conversation is not None
        assert conversation.id == created.id
        assert conversation.title == "测试对话"
        assert conversation.user_id == test_user.id
    
    def test_get_conversation_not_found(self, db_session: Session, test_user):
        """测试获取不存在的对话"""
        service = ConversationService(db_session)
        non_existent_id = uuid4()
        
        conversation = service.get_conversation(non_existent_id, test_user.id)
        
        assert conversation is None
    
    def test_get_conversation_wrong_user(self, db_session: Session, test_user):
        """测试获取其他用户的对话"""
        service = ConversationService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 为另一个用户创建对话
        conversation_data = ConversationCreate(title="其他用户的对话")
        other_conversation = service.create_conversation(other_user.id, conversation_data)
        
        # 尝试用test_user获取
        conversation = service.get_conversation(other_conversation.id, test_user.id)
        
        assert conversation is None
    
    def test_update_conversation_title(self, db_session: Session, test_user):
        """测试更新对话标题"""
        service = ConversationService(db_session)
        conversation_data = ConversationCreate(title="原始标题")
        conversation = service.create_conversation(test_user.id, conversation_data)
        
        update_data = ConversationUpdate(title="新标题")
        updated = service.update_conversation(conversation.id, test_user.id, update_data)
        
        assert updated is not None
        assert updated.title == "新标题"
        assert updated.id == conversation.id
    
    def test_update_conversation_pin(self, db_session: Session, test_user):
        """测试更新对话置顶状态"""
        service = ConversationService(db_session)
        conversation_data = ConversationCreate(title="测试对话")
        conversation = service.create_conversation(test_user.id, conversation_data)
        assert conversation.is_pinned is False
        
        update_data = ConversationUpdate(is_pinned=True)
        updated = service.update_conversation(conversation.id, test_user.id, update_data)
        
        assert updated is not None
        assert updated.is_pinned is True
    
    def test_update_conversation_not_found(self, db_session: Session, test_user):
        """测试更新不存在的对话"""
        service = ConversationService(db_session)
        non_existent_id = uuid4()
        update_data = ConversationUpdate(title="新标题")
        
        updated = service.update_conversation(non_existent_id, test_user.id, update_data)
        
        assert updated is None
    
    def test_delete_conversation_success(self, db_session: Session, test_user):
        """测试成功删除对话"""
        service = ConversationService(db_session)
        conversation_data = ConversationCreate(title="待删除对话")
        conversation = service.create_conversation(test_user.id, conversation_data)
        
        result = service.delete_conversation(conversation.id, test_user.id)
        
        assert result is True
        # 验证对话已被删除
        deleted = service.get_conversation(conversation.id, test_user.id)
        assert deleted is None
    
    def test_delete_conversation_not_found(self, db_session: Session, test_user):
        """测试删除不存在的对话"""
        service = ConversationService(db_session)
        non_existent_id = uuid4()
        
        result = service.delete_conversation(non_existent_id, test_user.id)
        
        assert result is False
    
    def test_delete_conversation_wrong_user(self, db_session: Session, test_user):
        """测试删除其他用户的对话"""
        service = ConversationService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 为另一个用户创建对话
        conversation_data = ConversationCreate(title="其他用户的对话")
        other_conversation = service.create_conversation(other_user.id, conversation_data)
        
        # 尝试用test_user删除
        result = service.delete_conversation(other_conversation.id, test_user.id)
        
        assert result is False
        # 验证对话仍然存在
        still_exists = service.get_conversation(other_conversation.id, other_user.id)
        assert still_exists is not None
    
    def test_update_last_accessed(self, db_session: Session, test_user):
        """测试更新最后访问时间"""
        service = ConversationService(db_session)
        conversation_data = ConversationCreate(title="测试对话")
        conversation = service.create_conversation(test_user.id, conversation_data)
        
        original_accessed = conversation.last_accessed_at
        
        # 等待一小段时间确保时间不同
        import time
        time.sleep(0.1)
        
        service.update_last_accessed(conversation.id)
        
        # 重新获取对话
        updated = service.get_conversation(conversation.id, test_user.id)
        assert updated is not None
        if original_accessed and updated.last_accessed_at:
            assert updated.last_accessed_at > original_accessed
