"""任务服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from uuid import UUID, uuid4
from shared.models.task import TaskCreate, TaskStatus, TaskType
from services.agent_service.src.services.task_service import TaskService
from shared.models.db_models import Task, Conversation
from services.agent_service.src.services.conversation_service import ConversationService
from shared.models.conversation import ConversationCreate


@pytest.mark.unit
class TestTaskService:
    """任务服务测试类"""
    
    def test_create_task_success(self, db_session: Session, test_user):
        """测试成功创建任务"""
        service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        
        task = service.create_task(test_user.id, task_data)
        
        assert task is not None
        assert task.user_id == test_user.id
        assert task.type == TaskType.SCREENPLAY.value
        assert task.status == TaskStatus.PENDING.value
        assert task.progress == 0
        assert task.params == {"prompt": "测试提示词"}
    
    def test_create_task_with_conversation(self, db_session: Session, test_user):
        """测试创建带对话ID的任务"""
        service = TaskService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        task_data = TaskCreate(
            type=TaskType.IMAGE,
            conversation_id=conversation.id,
            params={"prompt": "生成图片"}
        )
        
        task = service.create_task(test_user.id, task_data)
        
        assert task is not None
        assert task.conversation_id == conversation.id
    
    def test_get_tasks_empty(self, db_session: Session, test_user):
        """测试获取空任务列表"""
        service = TaskService(db_session)
        tasks, total = service.get_tasks(test_user.id)
        
        assert tasks == []
        assert total == 0
    
    def test_get_tasks_with_data(self, db_session: Session, test_user):
        """测试获取任务列表（有数据）"""
        service = TaskService(db_session)
        
        # 创建多个任务
        for i in range(5):
            task_data = TaskCreate(
                type=TaskType.IMAGE,
                params={"prompt": f"任务{i+1}"}
            )
            service.create_task(test_user.id, task_data)
        
        tasks, total = service.get_tasks(test_user.id)
        
        assert len(tasks) == 5
        assert total == 5
        assert all(t.user_id == test_user.id for t in tasks)
    
    def test_get_tasks_pagination(self, db_session: Session, test_user):
        """测试任务列表分页"""
        service = TaskService(db_session)
        
        # 创建10个任务
        for i in range(10):
            task_data = TaskCreate(
                type=TaskType.VIDEO,
                params={"prompt": f"任务{i+1}"}
            )
            service.create_task(test_user.id, task_data)
        
        # 第一页
        tasks, total = service.get_tasks(test_user.id, page=1, page_size=5)
        assert len(tasks) == 5
        assert total == 10
        
        # 第二页
        tasks, total = service.get_tasks(test_user.id, page=2, page_size=5)
        assert len(tasks) == 5
        assert total == 10
    
    def test_get_task_success(self, db_session: Session, test_user):
        """测试成功获取任务详情"""
        service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试任务"}
        )
        created = service.create_task(test_user.id, task_data)
        
        task = service.get_task(created.id, test_user.id)
        
        assert task is not None
        assert task.id == created.id
        assert task.type == TaskType.SCREENPLAY.value
        assert task.user_id == test_user.id
    
    def test_get_task_not_found(self, db_session: Session, test_user):
        """测试获取不存在的任务"""
        service = TaskService(db_session)
        non_existent_id = uuid4()
        
        task = service.get_task(non_existent_id, test_user.id)
        
        assert task is None
    
    def test_get_task_wrong_user(self, db_session: Session, test_user):
        """测试获取其他用户的任务"""
        service = TaskService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 为另一个用户创建任务
        task_data = TaskCreate(
            type=TaskType.IMAGE,
            params={"prompt": "其他用户的任务"}
        )
        other_task = service.create_task(other_user.id, task_data)
        
        # 尝试用test_user获取
        task = service.get_task(other_task.id, test_user.id)
        
        assert task is None
    
    def test_update_task_status_to_processing(self, db_session: Session, test_user):
        """测试更新任务状态为处理中"""
        service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.IMAGE,
            params={"prompt": "测试任务"}
        )
        task = service.create_task(test_user.id, task_data)
        
        updated = service.update_task_status(
            task.id,
            TaskStatus.PROCESSING,
            progress=50
        )
        
        assert updated is not None
        assert updated.status == TaskStatus.PROCESSING.value
        assert updated.progress == 50
        assert updated.completed_at is None
    
    def test_update_task_status_to_completed(self, db_session: Session, test_user):
        """测试更新任务状态为已完成"""
        service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.VIDEO,
            params={"prompt": "测试任务"}
        )
        task = service.create_task(test_user.id, task_data)
        
        result = {"url": "https://example.com/video.mp4"}
        updated = service.update_task_status(
            task.id,
            TaskStatus.COMPLETED,
            progress=100,
            result=result
        )
        
        assert updated is not None
        assert updated.status == TaskStatus.COMPLETED.value
        assert updated.progress == 100
        assert updated.result == result
        assert updated.completed_at is not None
    
    def test_update_task_status_to_failed(self, db_session: Session, test_user):
        """测试更新任务状态为失败"""
        service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.IMAGE,
            params={"prompt": "测试任务"}
        )
        task = service.create_task(test_user.id, task_data)
        
        error_message = "生成失败：网络错误"
        updated = service.update_task_status(
            task.id,
            TaskStatus.FAILED,
            error_message=error_message
        )
        
        assert updated is not None
        assert updated.status == TaskStatus.FAILED.value
        assert updated.error_message == error_message
        assert updated.completed_at is not None
    
    def test_update_task_status_not_found(self, db_session: Session, test_user):
        """测试更新不存在的任务状态"""
        service = TaskService(db_session)
        non_existent_id = uuid4()
        
        updated = service.update_task_status(
            non_existent_id,
            TaskStatus.PROCESSING
        )
        
        assert updated is None
    
    def test_get_task_progress_success(self, db_session: Session, test_user):
        """测试成功获取任务进度"""
        service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试任务"}
        )
        task = service.create_task(test_user.id, task_data)
        
        # 更新任务状态
        service.update_task_status(
            task.id,
            TaskStatus.PROCESSING,
            progress=75,
            result={"step": "生成中"}
        )
        
        progress = service.get_task_progress(task.id, test_user.id)
        
        assert progress is not None
        assert progress["status"] == TaskStatus.PROCESSING.value
        assert progress["progress"] == 75
        assert progress["result"] == {"step": "生成中"}
    
    def test_get_task_progress_not_found(self, db_session: Session, test_user):
        """测试获取不存在任务的进度"""
        service = TaskService(db_session)
        non_existent_id = uuid4()
        
        progress = service.get_task_progress(non_existent_id, test_user.id)
        
        assert progress is None
    
    def test_get_task_progress_wrong_user(self, db_session: Session, test_user):
        """测试获取其他用户任务的进度"""
        service = TaskService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 为另一个用户创建任务
        task_data = TaskCreate(
            type=TaskType.IMAGE,
            params={"prompt": "其他用户的任务"}
        )
        other_task = service.create_task(other_user.id, task_data)
        
        # 尝试用test_user获取进度
        progress = service.get_task_progress(other_task.id, test_user.id)
        
        assert progress is None
