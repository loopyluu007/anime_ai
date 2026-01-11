"""消息服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from uuid import UUID, uuid4
from datetime import datetime, timedelta
from shared.models.message import MessageCreate, MessageRole, MessageType
from services.agent_service.src.services.message_service import MessageService
from services.agent_service.src.services.conversation_service import ConversationService
from shared.models.conversation import ConversationCreate
from shared.models.db_models import Message, Conversation


@pytest.mark.unit
class TestMessageService:
    """消息服务测试类"""
    
    def test_get_messages_empty(self, db_session: Session, test_user):
        """测试获取空消息列表"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        messages, total = service.get_messages(conversation.id, test_user.id)
        
        assert messages == []
        assert total == 0
    
    def test_get_messages_with_data(self, db_session: Session, test_user):
        """测试获取消息列表（有数据）"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        # 创建多条消息
        for i in range(5):
            message_data = MessageCreate(
                conversation_id=conversation.id,
                role=MessageRole.USER if i % 2 == 0 else MessageRole.ASSISTANT,
                content=f"消息内容{i+1}",
                type=MessageType.TEXT
            )
            service.create_message(conversation.id, test_user.id, message_data)
        
        messages, total = service.get_messages(conversation.id, test_user.id)
        
        assert len(messages) == 5
        assert total == 5
        # 验证消息按创建时间倒序排列（最新的在前）
        assert messages[0].content == "消息内容5"
        assert messages[-1].content == "消息内容1"
    
    def test_get_messages_pagination(self, db_session: Session, test_user):
        """测试消息列表分页"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        # 创建10条消息
        for i in range(10):
            message_data = MessageCreate(
                conversation_id=conversation.id,
                role=MessageRole.USER,
                content=f"消息{i+1}",
                type=MessageType.TEXT
            )
            service.create_message(conversation.id, test_user.id, message_data)
        
        # 第一页
        messages, total = service.get_messages(conversation.id, test_user.id, page=1, page_size=5)
        assert len(messages) == 5
        assert total == 10
        
        # 第二页
        messages, total = service.get_messages(conversation.id, test_user.id, page=2, page_size=5)
        assert len(messages) == 5
        assert total == 10
    
    def test_get_messages_with_before_filter(self, db_session: Session, test_user):
        """测试使用before参数筛选消息"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        # 创建消息
        message_data1 = MessageCreate(
            conversation_id=conversation.id,
            role=MessageRole.USER,
            content="较早的消息",
            type=MessageType.TEXT
        )
        msg1 = service.create_message(conversation.id, test_user.id, message_data1)
        
        # 等待一秒确保时间差
        import time
        time.sleep(1)
        
        message_data2 = MessageCreate(
            conversation_id=conversation.id,
            role=MessageRole.USER,
            content="较新的消息",
            type=MessageType.TEXT
        )
        msg2 = service.create_message(conversation.id, test_user.id, message_data2)
        
        # 使用msg2的创建时间作为before参数
        before_time = msg2.created_at
        messages, total = service.get_messages(
            conversation.id, test_user.id, before=before_time
        )
        
        # 应该只返回msg1（在before_time之前的消息）
        assert total == 1
        assert len(messages) == 1
        assert messages[0].content == "较早的消息"
    
    def test_get_messages_invalid_conversation(self, db_session: Session, test_user):
        """测试获取不存在对话的消息"""
        service = MessageService(db_session)
        fake_conv_id = uuid4()
        
        messages, total = service.get_messages(fake_conv_id, test_user.id)
        
        assert messages == []
        assert total == 0
    
    def test_get_messages_wrong_user(self, db_session: Session, test_user):
        """测试获取其他用户对话的消息（权限验证）"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user_data = UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        )
        other_user = auth_service.create_user(other_user_data)
        
        # 为另一个用户创建对话
        conv_data = ConversationCreate(title="其他用户的对话")
        conversation = conv_service.create_conversation(other_user.id, conv_data)
        
        # 尝试用test_user获取other_user的对话消息
        messages, total = service.get_messages(conversation.id, test_user.id)
        
        # 应该返回空（权限验证失败）
        assert messages == []
        assert total == 0
    
    def test_create_message_success(self, db_session: Session, test_user):
        """测试成功创建消息"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        message_data = MessageCreate(
            conversation_id=conversation.id,
            role=MessageRole.USER,
            content="测试消息内容",
            type=MessageType.TEXT,
            metadata={"key": "value"}
        )
        
        message = service.create_message(conversation.id, test_user.id, message_data)
        
        assert message is not None
        assert message.conversation_id == conversation.id
        assert message.role == MessageRole.USER.value
        assert message.content == "测试消息内容"
        assert message.type == MessageType.TEXT.value
        assert message.metadata == {"key": "value"}
        
        # 验证对话的消息计数已更新
        db_session.refresh(conversation)
        assert conversation.message_count == 1
    
    def test_create_message_updates_conversation_count(self, db_session: Session, test_user):
        """测试创建消息后更新对话消息计数"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        assert conversation.message_count == 0
        
        # 创建多条消息
        for i in range(3):
            message_data = MessageCreate(
                conversation_id=conversation.id,
                role=MessageRole.USER,
                content=f"消息{i+1}",
                type=MessageType.TEXT
            )
            service.create_message(conversation.id, test_user.id, message_data)
        
        # 验证消息计数
        db_session.refresh(conversation)
        assert conversation.message_count == 3
    
    def test_create_message_invalid_conversation(self, db_session: Session, test_user):
        """测试在不存在对话中创建消息"""
        service = MessageService(db_session)
        fake_conv_id = uuid4()
        
        message_data = MessageCreate(
            conversation_id=fake_conv_id,
            role=MessageRole.USER,
            content="测试消息",
            type=MessageType.TEXT
        )
        
        message = service.create_message(fake_conv_id, test_user.id, message_data)
        
        assert message is None
    
    def test_create_message_wrong_user(self, db_session: Session, test_user):
        """测试在其他用户的对话中创建消息（权限验证）"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user_data = UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        )
        other_user = auth_service.create_user(other_user_data)
        
        # 为另一个用户创建对话
        conv_data = ConversationCreate(title="其他用户的对话")
        conversation = conv_service.create_conversation(other_user.id, conv_data)
        
        # 尝试用test_user在other_user的对话中创建消息
        message_data = MessageCreate(
            conversation_id=conversation.id,
            role=MessageRole.USER,
            content="测试消息",
            type=MessageType.TEXT
        )
        message = service.create_message(conversation.id, test_user.id, message_data)
        
        # 应该返回None（权限验证失败）
        assert message is None
    
    def test_get_message_success(self, db_session: Session, test_user):
        """测试成功获取单条消息"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话和消息
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        message_data = MessageCreate(
            conversation_id=conversation.id,
            role=MessageRole.USER,
            content="测试消息",
            type=MessageType.TEXT
        )
        created_message = service.create_message(conversation.id, test_user.id, message_data)
        
        # 获取消息
        message = service.get_message(created_message.id, conversation.id, test_user.id)
        
        assert message is not None
        assert message.id == created_message.id
        assert message.content == "测试消息"
    
    def test_get_message_not_found(self, db_session: Session, test_user):
        """测试获取不存在的消息"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        fake_message_id = uuid4()
        message = service.get_message(fake_message_id, conversation.id, test_user.id)
        
        assert message is None
    
    def test_get_message_wrong_conversation(self, db_session: Session, test_user):
        """测试获取其他对话的消息"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建两个对话
        conv_data1 = ConversationCreate(title="对话1")
        conversation1 = conv_service.create_conversation(test_user.id, conv_data1)
        
        conv_data2 = ConversationCreate(title="对话2")
        conversation2 = conv_service.create_conversation(test_user.id, conv_data2)
        
        # 在对话1中创建消息
        message_data = MessageCreate(
            conversation_id=conversation1.id,
            role=MessageRole.USER,
            content="对话1的消息",
            type=MessageType.TEXT
        )
        message = service.create_message(conversation1.id, test_user.id, message_data)
        
        # 尝试用对话2的ID获取消息
        result = service.get_message(message.id, conversation2.id, test_user.id)
        
        assert result is None
    
    def test_delete_message_success(self, db_session: Session, test_user):
        """测试成功删除消息"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话和消息
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        message_data = MessageCreate(
            conversation_id=conversation.id,
            role=MessageRole.USER,
            content="要删除的消息",
            type=MessageType.TEXT
        )
        message = service.create_message(conversation.id, test_user.id, message_data)
        
        # 验证消息计数
        db_session.refresh(conversation)
        assert conversation.message_count == 1
        
        # 删除消息
        result = service.delete_message(message.id, conversation.id, test_user.id)
        
        assert result is True
        
        # 验证消息已删除
        deleted_message = service.get_message(message.id, conversation.id, test_user.id)
        assert deleted_message is None
        
        # 验证消息计数已更新
        db_session.refresh(conversation)
        assert conversation.message_count == 0
    
    def test_delete_message_updates_count(self, db_session: Session, test_user):
        """测试删除消息后更新对话消息计数"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话和消息
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        # 创建3条消息
        messages = []
        for i in range(3):
            message_data = MessageCreate(
                conversation_id=conversation.id,
                role=MessageRole.USER,
                content=f"消息{i+1}",
                type=MessageType.TEXT
            )
            msg = service.create_message(conversation.id, test_user.id, message_data)
            messages.append(msg)
        
        db_session.refresh(conversation)
        assert conversation.message_count == 3
        
        # 删除一条消息
        service.delete_message(messages[0].id, conversation.id, test_user.id)
        
        # 验证消息计数
        db_session.refresh(conversation)
        assert conversation.message_count == 2
    
    def test_delete_message_not_found(self, db_session: Session, test_user):
        """测试删除不存在的消息"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        fake_message_id = uuid4()
        result = service.delete_message(fake_message_id, conversation.id, test_user.id)
        
        assert result is False
    
    def test_delete_message_wrong_user(self, db_session: Session, test_user):
        """测试删除其他用户的消息（权限验证）"""
        service = MessageService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user_data = UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        )
        other_user = auth_service.create_user(other_user_data)
        
        # 为另一个用户创建对话和消息
        conv_data = ConversationCreate(title="其他用户的对话")
        conversation = conv_service.create_conversation(other_user.id, conv_data)
        
        message_data = MessageCreate(
            conversation_id=conversation.id,
            role=MessageRole.USER,
            content="其他用户的消息",
            type=MessageType.TEXT
        )
        message = service.create_message(conversation.id, other_user.id, message_data)
        
        # 尝试用test_user删除other_user的消息
        result = service.delete_message(message.id, conversation.id, test_user.id)
        
        # 应该返回False（权限验证失败）
        assert result is False
        
        # 验证消息仍然存在
        existing_message = service.get_message(message.id, conversation.id, other_user.id)
        assert existing_message is not None
