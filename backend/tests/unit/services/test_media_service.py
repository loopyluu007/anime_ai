"""媒体服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from uuid import UUID, uuid4
from services.media_service.src.services.image_service import ImageService
from services.media_service.src.services.video_service import VideoService
from shared.models.db_models import Task, MediaFile
from shared.models.task import TaskStatus, TaskType
from unittest.mock import AsyncMock, MagicMock, patch


@pytest.mark.unit
class TestImageService:
    """图片生成服务测试类"""
    
    def test_create_image_task_success(self, db_session: Session, test_user):
        """测试成功创建图片生成任务"""
        service = ImageService(db_session)
        
        task = service.create_image_task(
            user_id=test_user.id,
            prompt="生成一张美丽的风景图",
            model="gemini-3-pro-image-preview-hd",
            size="1024x1024"
        )
        
        assert task is not None
        assert task.user_id == test_user.id
        assert task.type == TaskType.IMAGE.value
        assert task.status == TaskStatus.PENDING.value
        assert task.progress == 0
        assert task.params["prompt"] == "生成一张美丽的风景图"
        assert task.params["model"] == "gemini-3-pro-image-preview-hd"
        assert task.params["size"] == "1024x1024"
    
    def test_create_image_task_with_reference_images(self, db_session: Session, test_user):
        """测试创建带参考图片的图片生成任务"""
        service = ImageService(db_session)
        reference_images = ["https://example.com/img1.jpg", "https://example.com/img2.jpg"]
        
        task = service.create_image_task(
            user_id=test_user.id,
            prompt="生成图片",
            reference_images=reference_images
        )
        
        assert task is not None
        assert task.params["reference_images"] == reference_images
    
    @pytest.mark.asyncio
    async def test_generate_image_success(self, db_session: Session, test_user):
        """测试成功生成图片"""
        service = ImageService(db_session)
        
        # 创建任务
        task = service.create_image_task(
            user_id=test_user.id,
            prompt="生成图片"
        )
        
        # Mock Gemini客户端
        mock_response = {
            "data": [
                {
                    "url": "https://example.com/generated-image.jpg"
                }
            ]
        }
        
        with patch.object(service.gemini_client, 'generate_image', new_callable=AsyncMock) as mock_generate:
            mock_generate.return_value = mock_response
            
            media_file = await service.generate_image(task.id)
            
            assert media_file is not None
            assert media_file.user_id == test_user.id
            assert media_file.type == "image"
            assert media_file.url == "https://example.com/generated-image.jpg"
            
            # 验证任务状态已更新
            updated_task = db_session.query(Task).filter(Task.id == task.id).first()
            assert updated_task.status == TaskStatus.COMPLETED.value
            assert updated_task.progress == 100
            assert updated_task.result is not None
    
    @pytest.mark.asyncio
    async def test_generate_image_task_not_found(self, db_session: Session, test_user):
        """测试生成图片时任务不存在"""
        service = ImageService(db_session)
        non_existent_id = uuid4()
        
        media_file = await service.generate_image(non_existent_id)
        
        assert media_file is None
    
    @pytest.mark.asyncio
    async def test_generate_image_api_error(self, db_session: Session, test_user):
        """测试生成图片时API错误"""
        service = ImageService(db_session)
        
        # 创建任务
        task = service.create_image_task(
            user_id=test_user.id,
            prompt="生成图片"
        )
        
        # Mock Gemini客户端返回错误
        with patch.object(service.gemini_client, 'generate_image', new_callable=AsyncMock) as mock_generate:
            mock_generate.side_effect = Exception("API调用失败")
            
            with pytest.raises(Exception):
                await service.generate_image(task.id)
            
            # 验证任务状态已更新为失败
            updated_task = db_session.query(Task).filter(Task.id == task.id).first()
            assert updated_task.status == TaskStatus.FAILED.value
            assert updated_task.error_message is not None
    
    def test_get_media_file_success(self, db_session: Session, test_user):
        """测试成功获取媒体文件"""
        service = ImageService(db_session)
        
        # 创建媒体文件
        media_file = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="path/to/image.jpg",
            url="https://example.com/image.jpg",
            metadata={"prompt": "测试图片"}
        )
        db_session.add(media_file)
        db_session.commit()
        db_session.refresh(media_file)
        
        result = service.get_media_file(media_file.id, test_user.id)
        
        assert result is not None
        assert result.id == media_file.id
        assert result.url == "https://example.com/image.jpg"
    
    def test_get_media_file_not_found(self, db_session: Session, test_user):
        """测试获取不存在的媒体文件"""
        service = ImageService(db_session)
        non_existent_id = uuid4()
        
        media_file = service.get_media_file(non_existent_id, test_user.id)
        
        assert media_file is None
    
    def test_get_media_file_wrong_user(self, db_session: Session, test_user):
        """测试获取其他用户的媒体文件"""
        service = ImageService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 为另一个用户创建媒体文件
        media_file = MediaFile(
            user_id=other_user.id,
            type="image",
            storage_path="path/to/image.jpg",
            url="https://example.com/image.jpg"
        )
        db_session.add(media_file)
        db_session.commit()
        db_session.refresh(media_file)
        
        # 尝试用test_user获取
        result = service.get_media_file(media_file.id, test_user.id)
        
        assert result is None


@pytest.mark.unit
class TestVideoService:
    """视频生成服务测试类"""
    
    def test_create_video_task_success(self, db_session: Session, test_user):
        """测试成功创建视频生成任务"""
        service = VideoService(db_session)
        
        task = service.create_video_task(
            user_id=test_user.id,
            prompt="生成一个10秒的视频",
            model="sora-1",
            seconds="10"
        )
        
        assert task is not None
        assert task.user_id == test_user.id
        assert task.type == TaskType.VIDEO.value
        assert task.status == TaskStatus.PENDING.value
        assert task.progress == 0
        assert task.params["prompt"] == "生成一个10秒的视频"
        assert task.params["model"] == "sora-1"
        assert task.params["seconds"] == "10"
    
    def test_create_video_task_with_image_url(self, db_session: Session, test_user):
        """测试创建带图片URL的视频生成任务"""
        service = VideoService(db_session)
        image_url = "https://example.com/image.jpg"
        
        task = service.create_video_task(
            user_id=test_user.id,
            prompt="基于图片生成视频",
            image_url=image_url
        )
        
        assert task is not None
        assert task.params["image_url"] == image_url
    
    def test_create_video_task_with_image_id(self, db_session: Session, test_user):
        """测试创建带图片ID的视频生成任务"""
        service = VideoService(db_session)
        
        # 创建媒体文件
        media_file = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="path/to/image.jpg",
            url="https://example.com/image.jpg"
        )
        db_session.add(media_file)
        db_session.commit()
        db_session.refresh(media_file)
        
        task = service.create_video_task(
            user_id=test_user.id,
            prompt="基于图片生成视频",
            image_id=str(media_file.id)
        )
        
        assert task is not None
        assert task.params["image_id"] == str(media_file.id)
    
    def test_create_video_task_with_reference_images(self, db_session: Session, test_user):
        """测试创建带参考图片的视频生成任务"""
        service = VideoService(db_session)
        reference_images = ["https://example.com/img1.jpg", "https://example.com/img2.jpg"]
        
        task = service.create_video_task(
            user_id=test_user.id,
            prompt="生成视频",
            reference_images=reference_images
        )
        
        assert task is not None
        assert task.params["reference_images"] == reference_images
    
    @pytest.mark.asyncio
    async def test_generate_video_success(self, db_session: Session, test_user):
        """测试成功生成视频"""
        service = VideoService(db_session)
        
        # 创建任务
        task = service.create_video_task(
            user_id=test_user.id,
            prompt="生成视频"
        )
        
        # Mock Tuzi客户端
        mock_generate_response = {
            "task_id": "tuzi-task-123"
        }
        mock_wait_response = {
            "url": "https://example.com/generated-video.mp4"
        }
        
        with patch.object(service.tuzi_client, 'generate_video', new_callable=AsyncMock) as mock_generate, \
             patch.object(service.tuzi_client, 'wait_for_video', new_callable=AsyncMock) as mock_wait:
            mock_generate.return_value = mock_generate_response
            mock_wait.return_value = mock_wait_response
            
            media_file = await service.generate_video(task.id)
            
            assert media_file is not None
            assert media_file.user_id == test_user.id
            assert media_file.type == "video"
            assert media_file.url == "https://example.com/generated-video.mp4"
            
            # 验证任务状态已更新
            updated_task = db_session.query(Task).filter(Task.id == task.id).first()
            assert updated_task.status == TaskStatus.COMPLETED.value
            assert updated_task.progress == 100
            assert updated_task.result is not None
    
    @pytest.mark.asyncio
    async def test_generate_video_with_image_id(self, db_session: Session, test_user):
        """测试使用图片ID生成视频"""
        service = VideoService(db_session)
        
        # 创建媒体文件
        media_file = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="path/to/image.jpg",
            url="https://example.com/image.jpg"
        )
        db_session.add(media_file)
        db_session.commit()
        db_session.refresh(media_file)
        
        # 创建任务
        task = service.create_video_task(
            user_id=test_user.id,
            prompt="生成视频",
            image_id=str(media_file.id)
        )
        
        # Mock Tuzi客户端
        mock_generate_response = {
            "task_id": "tuzi-task-123"
        }
        mock_wait_response = {
            "url": "https://example.com/generated-video.mp4"
        }
        
        with patch.object(service.tuzi_client, 'generate_video', new_callable=AsyncMock) as mock_generate, \
             patch.object(service.tuzi_client, 'wait_for_video', new_callable=AsyncMock) as mock_wait:
            mock_generate.return_value = mock_generate_response
            mock_wait.return_value = mock_wait_response
            
            result = await service.generate_video(task.id)
            
            assert result is not None
            # 验证generate_video被调用时使用了正确的image_url
            mock_generate.assert_called_once()
            call_args = mock_generate.call_args
            assert call_args[1]["image_url"] == "https://example.com/image.jpg"
    
    @pytest.mark.asyncio
    async def test_generate_video_task_not_found(self, db_session: Session, test_user):
        """测试生成视频时任务不存在"""
        service = VideoService(db_session)
        non_existent_id = uuid4()
        
        media_file = await service.generate_video(non_existent_id)
        
        assert media_file is None
    
    @pytest.mark.asyncio
    async def test_generate_video_api_error(self, db_session: Session, test_user):
        """测试生成视频时API错误"""
        service = VideoService(db_session)
        
        # 创建任务
        task = service.create_video_task(
            user_id=test_user.id,
            prompt="生成视频"
        )
        
        # Mock Tuzi客户端返回错误
        with patch.object(service.tuzi_client, 'generate_video', new_callable=AsyncMock) as mock_generate:
            mock_generate.side_effect = Exception("API调用失败")
            
            with pytest.raises(Exception):
                await service.generate_video(task.id)
            
            # 验证任务状态已更新为失败
            updated_task = db_session.query(Task).filter(Task.id == task.id).first()
            assert updated_task.status == TaskStatus.FAILED.value
            assert updated_task.error_message is not None
    
    def test_get_media_file_success(self, db_session: Session, test_user):
        """测试成功获取媒体文件"""
        service = VideoService(db_session)
        
        # 创建媒体文件
        media_file = MediaFile(
            user_id=test_user.id,
            type="video",
            storage_path="path/to/video.mp4",
            url="https://example.com/video.mp4",
            duration=10,
            metadata={"prompt": "测试视频"}
        )
        db_session.add(media_file)
        db_session.commit()
        db_session.refresh(media_file)
        
        result = service.get_media_file(media_file.id, test_user.id)
        
        assert result is not None
        assert result.id == media_file.id
        assert result.url == "https://example.com/video.mp4"
        assert result.duration == 10
    
    def test_get_media_file_not_found(self, db_session: Session, test_user):
        """测试获取不存在的媒体文件"""
        service = VideoService(db_session)
        non_existent_id = uuid4()
        
        media_file = service.get_media_file(non_existent_id, test_user.id)
        
        assert media_file is None
    
    def test_get_media_file_wrong_user(self, db_session: Session, test_user):
        """测试获取其他用户的媒体文件"""
        service = VideoService(db_session)
        
        # 创建另一个用户
        from shared.models.user import UserCreate
        from services.agent_service.src.services.auth_service import AuthService
        auth_service = AuthService(db_session)
        other_user = auth_service.create_user(UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        ))
        
        # 为另一个用户创建媒体文件
        media_file = MediaFile(
            user_id=other_user.id,
            type="video",
            storage_path="path/to/video.mp4",
            url="https://example.com/video.mp4"
        )
        db_session.add(media_file)
        db_session.commit()
        db_session.refresh(media_file)
        
        # 尝试用test_user获取
        result = service.get_media_file(media_file.id, test_user.id)
        
        assert result is None
