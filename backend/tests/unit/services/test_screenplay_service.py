"""剧本服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from uuid import UUID, uuid4
from shared.models.screenplay import ScreenplayStatus, SceneStatus
from services.agent_service.src.services.screenplay_service import ScreenplayService
from services.agent_service.src.services.task_service import TaskService
from shared.models.db_models import Screenplay, Task
from shared.models.task import TaskCreate, TaskStatus, TaskType
from unittest.mock import AsyncMock, MagicMock, patch


@pytest.mark.unit
class TestScreenplayService:
    """剧本服务测试类"""
    
    def test_get_screenplay_success(self, db_session: Session, test_user):
        """测试成功获取剧本详情"""
        service = ScreenplayService(db_session)
        
        # 创建任务
        task_service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        task = task_service.create_task(test_user.id, task_data)
        
        # 创建剧本（手动创建，因为create_draft需要mock GLM客户端）
        screenplay = Screenplay(
            task_id=task.id,
            user_id=test_user.id,
            title="测试剧本",
            status=ScreenplayStatus.DRAFT.value
        )
        db_session.add(screenplay)
        db_session.commit()
        db_session.refresh(screenplay)
        
        result = service.get_screenplay(screenplay.id, test_user.id)
        
        assert result is not None
        assert result.id == screenplay.id
        assert result.title == "测试剧本"
        assert result.user_id == test_user.id
        assert result.status == ScreenplayStatus.DRAFT.value
    
    def test_get_screenplay_not_found(self, db_session: Session, test_user):
        """测试获取不存在的剧本"""
        service = ScreenplayService(db_session)
        non_existent_id = uuid4()
        
        screenplay = service.get_screenplay(non_existent_id, test_user.id)
        
        assert screenplay is None
    
    def test_get_screenplay_wrong_user(self, db_session: Session, test_user):
        """测试获取其他用户的剧本"""
        service = ScreenplayService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 创建任务
        task_service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        task = task_service.create_task(other_user.id, task_data)
        
        # 为另一个用户创建剧本
        screenplay = Screenplay(
            task_id=task.id,
            user_id=other_user.id,
            title="其他用户的剧本",
            status=ScreenplayStatus.DRAFT.value
        )
        db_session.add(screenplay)
        db_session.commit()
        db_session.refresh(screenplay)
        
        # 尝试用test_user获取
        result = service.get_screenplay(screenplay.id, test_user.id)
        
        assert result is None
    
    @pytest.mark.asyncio
    async def test_create_draft_success(self, db_session: Session, test_user):
        """测试成功创建剧本草稿"""
        service = ScreenplayService(db_session)
        
        # 创建任务
        task_service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        task = task_service.create_task(test_user.id, task_data)
        
        # Mock GLM客户端
        mock_screenplay_data = {
            "script_title": "测试剧本",
            "scenes": [
                {
                    "scene_id": 1,
                    "narration": "场景1描述",
                    "image_prompt": "场景1图片提示",
                    "video_prompt": "场景1视频提示",
                    "character_description": "角色描述"
                }
            ],
            "characters": [
                {
                    "name": "角色1",
                    "description": "角色1描述"
                }
            ]
        }
        
        with patch.object(service.glm_client, 'generate_screenplay', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = mock_screenplay_data
            
            screenplay = await service.create_draft(
                user_id=test_user.id,
                task_id=task.id,
                prompt="测试提示词",
                scene_count=1,
                character_count=1
            )
            
            assert screenplay is not None
            assert screenplay.title == "测试剧本"
            assert screenplay.user_id == test_user.id
            assert screenplay.status == ScreenplayStatus.DRAFT.value
            assert screenplay.task_id == task.id
            
            # 验证任务状态已更新
            updated_task = task_service.get_task(task.id, test_user.id)
            assert updated_task.status == TaskStatus.COMPLETED.value
            assert updated_task.progress == 100
    
    @pytest.mark.asyncio
    async def test_create_draft_task_not_found(self, db_session: Session, test_user):
        """测试创建剧本草稿时任务不存在"""
        service = ScreenplayService(db_session)
        non_existent_task_id = uuid4()
        
        with pytest.raises(ValueError, match="任务不存在"):
            await service.create_draft(
                user_id=test_user.id,
                task_id=non_existent_task_id,
                prompt="测试提示词"
            )
    
    def test_confirm_screenplay_success(self, db_session: Session, test_user):
        """测试成功确认剧本"""
        service = ScreenplayService(db_session)
        
        # 创建任务
        task_service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        task = task_service.create_task(test_user.id, task_data)
        
        # 创建草稿状态的剧本
        screenplay = Screenplay(
            task_id=task.id,
            user_id=test_user.id,
            title="测试剧本",
            status=ScreenplayStatus.DRAFT.value
        )
        db_session.add(screenplay)
        db_session.commit()
        db_session.refresh(screenplay)
        
        confirmed = service.confirm_screenplay(screenplay.id, test_user.id)
        
        assert confirmed is not None
        assert confirmed.status == ScreenplayStatus.GENERATING.value
        assert confirmed.id == screenplay.id
        
        # 验证任务状态已更新
        updated_task = task_service.get_task(task.id, test_user.id)
        assert updated_task.status == TaskStatus.PROCESSING.value
    
    def test_confirm_screenplay_not_found(self, db_session: Session, test_user):
        """测试确认不存在的剧本"""
        service = ScreenplayService(db_session)
        non_existent_id = uuid4()
        
        confirmed = service.confirm_screenplay(non_existent_id, test_user.id)
        
        assert confirmed is None
    
    def test_confirm_screenplay_wrong_status(self, db_session: Session, test_user):
        """测试确认非草稿状态的剧本"""
        service = ScreenplayService(db_session)
        
        # 创建任务
        task_service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        task = task_service.create_task(test_user.id, task_data)
        
        # 创建非草稿状态的剧本
        screenplay = Screenplay(
            task_id=task.id,
            user_id=test_user.id,
            title="测试剧本",
            status=ScreenplayStatus.GENERATING.value
        )
        db_session.add(screenplay)
        db_session.commit()
        db_session.refresh(screenplay)
        
        with pytest.raises(ValueError, match="只能确认草稿状态的剧本"):
            service.confirm_screenplay(screenplay.id, test_user.id)
    
    def test_update_screenplay_title(self, db_session: Session, test_user):
        """测试更新剧本标题"""
        service = ScreenplayService(db_session)
        
        # 创建任务
        task_service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        task = task_service.create_task(test_user.id, task_data)
        
        # 创建剧本
        screenplay = Screenplay(
            task_id=task.id,
            user_id=test_user.id,
            title="原始标题",
            status=ScreenplayStatus.DRAFT.value
        )
        db_session.add(screenplay)
        db_session.commit()
        db_session.refresh(screenplay)
        
        updated = service.update_screenplay(screenplay.id, test_user.id, title="新标题")
        
        assert updated is not None
        assert updated.title == "新标题"
        assert updated.id == screenplay.id
    
    def test_update_screenplay_not_found(self, db_session: Session, test_user):
        """测试更新不存在的剧本"""
        service = ScreenplayService(db_session)
        non_existent_id = uuid4()
        
        updated = service.update_screenplay(non_existent_id, test_user.id, title="新标题")
        
        assert updated is None
    
    def test_update_screenplay_wrong_user(self, db_session: Session, test_user):
        """测试更新其他用户的剧本"""
        service = ScreenplayService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 创建任务
        task_service = TaskService(db_session)
        task_data = TaskCreate(
            type=TaskType.SCREENPLAY,
            params={"prompt": "测试提示词"}
        )
        task = task_service.create_task(other_user.id, task_data)
        
        # 为另一个用户创建剧本
        screenplay = Screenplay(
            task_id=task.id,
            user_id=other_user.id,
            title="其他用户的剧本",
            status=ScreenplayStatus.DRAFT.value
        )
        db_session.add(screenplay)
        db_session.commit()
        db_session.refresh(screenplay)
        
        # 尝试用test_user更新
        updated = service.update_screenplay(screenplay.id, test_user.id, title="新标题")
        
        assert updated is None
