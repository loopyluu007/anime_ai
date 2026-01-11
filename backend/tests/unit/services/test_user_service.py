"""用户数据服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from uuid import UUID, uuid4
from services.data_service.src.services.user_service import UserService
from shared.models.db_models import User, Conversation, Task, Message
from services.agent_service.src.services.auth_service import AuthService
from services.agent_service.src.services.conversation_service import ConversationService
from shared.models.user import UserCreate
from shared.models.conversation import ConversationCreate
from datetime import datetime, timedelta


@pytest.mark.unit
class TestUserService:
    """用户数据服务测试类"""
    
    def test_get_user_success(self, db_session: Session, test_user):
        """测试成功获取用户信息"""
        service = UserService(db_session)
        
        user = service.get_user(test_user.id)
        
        assert user is not None
        assert user.id == test_user.id
        assert user.username == test_user.username
        assert user.email == test_user.email
    
    def test_get_user_not_found(self, db_session: Session):
        """测试获取不存在的用户"""
        service = UserService(db_session)
        fake_user_id = uuid4()
        
        user = service.get_user(fake_user_id)
        
        assert user is None
    
    def test_update_user_username(self, db_session: Session, test_user):
        """测试更新用户名"""
        service = UserService(db_session)
        
        new_username = "newusername"
        updated_user = service.update_user(test_user.id, username=new_username)
        
        assert updated_user is not None
        assert updated_user.username == new_username
        assert updated_user.email == test_user.email  # 邮箱未变
        
        # 验证数据库中的更新
        db_session.refresh(updated_user)
        assert updated_user.username == new_username
    
    def test_update_user_avatar_url(self, db_session: Session, test_user):
        """测试更新头像URL"""
        service = UserService(db_session)
        
        new_avatar_url = "https://example.com/avatar.jpg"
        updated_user = service.update_user(test_user.id, avatar_url=new_avatar_url)
        
        assert updated_user is not None
        assert updated_user.avatar_url == new_avatar_url
        assert updated_user.username == test_user.username  # 用户名未变
        
        # 验证数据库中的更新
        db_session.refresh(updated_user)
        assert updated_user.avatar_url == new_avatar_url
    
    def test_update_user_both_fields(self, db_session: Session, test_user):
        """测试同时更新用户名和头像"""
        service = UserService(db_session)
        
        new_username = "newusername"
        new_avatar_url = "https://example.com/new-avatar.jpg"
        updated_user = service.update_user(
            test_user.id,
            username=new_username,
            avatar_url=new_avatar_url
        )
        
        assert updated_user is not None
        assert updated_user.username == new_username
        assert updated_user.avatar_url == new_avatar_url
        
        # 验证数据库中的更新
        db_session.refresh(updated_user)
        assert updated_user.username == new_username
        assert updated_user.avatar_url == new_avatar_url
    
    def test_update_user_no_changes(self, db_session: Session, test_user):
        """测试不提供任何更新字段"""
        service = UserService(db_session)
        
        original_username = test_user.username
        original_avatar_url = test_user.avatar_url
        
        updated_user = service.update_user(test_user.id)
        
        assert updated_user is not None
        assert updated_user.username == original_username
        assert updated_user.avatar_url == original_avatar_url
    
    def test_update_user_not_found(self, db_session: Session):
        """测试更新不存在的用户"""
        service = UserService(db_session)
        fake_user_id = uuid4()
        
        updated_user = service.update_user(fake_user_id, username="newusername")
        
        assert updated_user is None
    
    def test_get_user_stats_empty(self, db_session: Session, test_user):
        """测试获取空用户统计数据"""
        service = UserService(db_session)
        
        stats = service.get_user_stats(test_user.id)
        
        assert stats is not None
        assert stats["conversation_count"] == 0
        assert stats["message_count"] == 0
        assert stats["task_count"] == 0
        assert stats["completed_task_count"] == 0
        assert stats["recent_activity"] == 0
        assert stats["created_at"] is not None
    
    def test_get_user_stats_with_conversations(self, db_session: Session, test_user):
        """测试获取有对话的用户统计数据"""
        service = UserService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建多个对话
        for i in range(5):
            conv_data = ConversationCreate(title=f"对话{i+1}")
            conv_service.create_conversation(test_user.id, conv_data)
        
        stats = service.get_user_stats(test_user.id)
        
        assert stats is not None
        assert stats["conversation_count"] == 5
    
    def test_get_user_stats_with_messages(self, db_session: Session, test_user):
        """测试获取有消息的用户统计数据"""
        service = UserService(db_session)
        conv_service = ConversationService(db_session)
        from services.agent_service.src.services.message_service import MessageService
        from shared.models.message import MessageCreate, MessageRole, MessageType
        message_service = MessageService(db_session)
        
        # 创建对话和消息
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        # 创建多条消息
        for i in range(10):
            message_data = MessageCreate(
                conversation_id=conversation.id,
                role=MessageRole.USER if i % 2 == 0 else MessageRole.ASSISTANT,
                content=f"消息{i+1}",
                type=MessageType.TEXT
            )
            message_service.create_message(conversation.id, test_user.id, message_data)
        
        stats = service.get_user_stats(test_user.id)
        
        assert stats is not None
        assert stats["message_count"] == 10
    
    def test_get_user_stats_with_tasks(self, db_session: Session, test_user):
        """测试获取有任务的用户统计数据"""
        service = UserService(db_session)
        
        # 创建多个任务
        for i in range(8):
            task = Task(
                user_id=test_user.id,
                type="screenplay" if i % 3 == 0 else "image",
                status="completed" if i % 2 == 0 else "pending",
                params={"prompt": f"任务{i+1}"}
            )
            if i % 2 == 0:
                task.completed_at = datetime.utcnow()
            db_session.add(task)
        db_session.commit()
        
        stats = service.get_user_stats(test_user.id)
        
        assert stats is not None
        assert stats["task_count"] == 8
        assert stats["completed_task_count"] == 4  # 一半任务完成
    
    def test_get_user_stats_recent_activity(self, db_session: Session, test_user):
        """测试获取最近活跃度统计"""
        service = UserService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建最近访问的对话（7天内）
        conv_data = ConversationCreate(title="最近对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        conversation.last_accessed_at = datetime.utcnow() - timedelta(days=3)
        db_session.commit()
        
        # 创建较旧的对话（超过7天）
        old_conv_data = ConversationCreate(title="旧对话")
        old_conversation = conv_service.create_conversation(test_user.id, old_conv_data)
        old_conversation.last_accessed_at = datetime.utcnow() - timedelta(days=10)
        db_session.commit()
        
        stats = service.get_user_stats(test_user.id)
        
        assert stats is not None
        assert stats["recent_activity"] >= 1  # 至少有一个最近访问的对话
    
    def test_get_user_stats_comprehensive(self, db_session: Session, test_user):
        """测试获取综合用户统计数据"""
        service = UserService(db_session)
        conv_service = ConversationService(db_session)
        from services.agent_service.src.services.message_service import MessageService
        from shared.models.message import MessageCreate, MessageRole, MessageType
        message_service = MessageService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="综合测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        # 创建消息
        for i in range(5):
            message_data = MessageCreate(
                conversation_id=conversation.id,
                role=MessageRole.USER,
                content=f"消息{i+1}",
                type=MessageType.TEXT
            )
            message_service.create_message(conversation.id, test_user.id, message_data)
        
        # 创建任务
        for i in range(3):
            task = Task(
                user_id=test_user.id,
                type="screenplay",
                status="completed" if i == 0 else "pending",
                params={"prompt": f"任务{i+1}"}
            )
            if i == 0:  # 第一个任务完成
                task.completed_at = datetime.utcnow()
            db_session.add(task)
        db_session.commit()
        
        stats = service.get_user_stats(test_user.id)
        
        assert stats is not None
        assert stats["conversation_count"] >= 1
        assert stats["message_count"] >= 5
        assert stats["task_count"] >= 3
        assert stats["completed_task_count"] >= 1
        assert stats["created_at"] is not None
    
    def test_get_user_stats_not_found(self, db_session: Session):
        """测试获取不存在用户的统计数据"""
        service = UserService(db_session)
        fake_user_id = uuid4()
        
        stats = service.get_user_stats(fake_user_id)
        
        # 应该返回空字典
        assert stats == {}
    
    def test_get_user_stats_multiple_users(self, db_session: Session, test_user):
        """测试多个用户的统计数据隔离"""
        service = UserService(db_session)
        auth_service = AuthService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建另一个用户
        other_user_data = UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        )
        other_user = auth_service.create_user(other_user_data)
        
        # 为两个用户创建对话
        conv1 = conv_service.create_conversation(
            test_user.id,
            ConversationCreate(title="用户1的对话")
        )
        conv2 = conv_service.create_conversation(
            other_user.id,
            ConversationCreate(title="用户2的对话")
        )
        
        # 获取各自的统计数据
        stats1 = service.get_user_stats(test_user.id)
        stats2 = service.get_user_stats(other_user.id)
        
        # 验证数据隔离
        assert stats1["conversation_count"] == 1
        assert stats2["conversation_count"] == 1
        assert stats1 != stats2
