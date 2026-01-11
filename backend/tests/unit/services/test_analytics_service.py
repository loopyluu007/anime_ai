"""数据分析服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from uuid import UUID, uuid4
from datetime import datetime, timedelta
from services.data_service.src.services.analytics_service import AnalyticsService
from shared.models.db_models import User, Conversation, Task, MediaFile
from services.agent_service.src.services.auth_service import AuthService
from services.agent_service.src.services.conversation_service import ConversationService
from shared.models.user import UserCreate
from shared.models.conversation import ConversationCreate


@pytest.mark.unit
class TestAnalyticsService:
    """数据分析服务测试类"""
    
    def test_get_overview_stats_no_data(self, db_session: Session):
        """测试获取空系统概览统计"""
        service = AnalyticsService(db_session)
        
        stats = service.get_overview_stats()
        
        assert stats is not None
        assert stats["user_count"] == 0
        assert stats["conversation"]["total_count"] == 0
        assert stats["task"]["total_count"] == 0
        assert stats["media"]["total_count"] == 0
        assert stats["media"]["total_size_bytes"] == 0
    
    def test_get_overview_stats_with_data(self, db_session: Session, test_user):
        """测试获取有数据的系统概览统计"""
        service = AnalyticsService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        # 直接创建任务对象
        task = Task(
            user_id=test_user.id,
            conversation_id=conversation.id,
            type="screenplay",
            status="pending",
            params={"prompt": "测试"}
        )
        db_session.add(task)
        db_session.commit()
        db_session.refresh(task)
        
        # 创建媒体文件
        media = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="/path/to/image.jpg",
            url="https://example.com/image.jpg",
            size=1024000  # 1MB
        )
        db_session.add(media)
        db_session.commit()
        
        stats = service.get_overview_stats()
        
        assert stats["user_count"] >= 1
        assert stats["conversation"]["total_count"] >= 1
        assert stats["task"]["total_count"] >= 1
        assert stats["media"]["total_count"] >= 1
        assert stats["media"]["total_size_bytes"] >= 1024000
        assert stats["media"]["total_size_mb"] > 0
    
    def test_get_overview_stats_for_user(self, db_session: Session, test_user):
        """测试获取特定用户的系统概览统计"""
        service = AnalyticsService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="用户对话")
        conversation = conv_service.create_conversation(test_user.id, conv_data)
        
        stats = service.get_overview_stats(user_id=test_user.id)
        
        assert stats is not None
        assert stats["user_count"] == 1
        assert stats["conversation"]["total_count"] >= 1
    
    def test_get_task_analytics_no_data(self, db_session: Session):
        """测试获取空任务分析"""
        service = AnalyticsService(db_session)
        
        analytics = service.get_task_analytics()
        
        assert analytics is not None
        assert "stats" in analytics
        assert "trend" in analytics
        assert analytics["stats"]["total_count"] == 0
    
    def test_get_task_analytics_with_data(self, db_session: Session, test_user):
        """测试获取有数据的任务分析"""
        service = AnalyticsService(db_session)
        
        # 创建多个任务
        for i in range(5):
            task = Task(
                user_id=test_user.id,
                type="screenplay" if i % 2 == 0 else "image",
                status="completed" if i % 2 == 0 else "processing",
                params={"prompt": f"任务{i+1}"}
            )
            if i % 2 == 0:
                task.completed_at = datetime.utcnow()
            db_session.add(task)
        db_session.commit()
        
        analytics = service.get_task_analytics(user_id=test_user.id)
        
        assert analytics is not None
        assert analytics["stats"]["total_count"] >= 5
        assert "trend" in analytics
    
    def test_get_task_analytics_with_date_range(self, db_session: Session, test_user):
        """测试使用日期范围获取任务分析"""
        service = AnalyticsService(db_session)
        
        # 创建任务
        task = Task(
            user_id=test_user.id,
            type="screenplay",
            status="pending",
            params={"prompt": "测试"}
        )
        db_session.add(task)
        db_session.commit()
        
        start_date = datetime.utcnow() - timedelta(days=7)
        end_date = datetime.utcnow()
        
        analytics = service.get_task_analytics(
            user_id=test_user.id,
            start_date=start_date,
            end_date=end_date
        )
        
        assert analytics is not None
        assert "stats" in analytics
        assert "trend" in analytics
    
    def test_get_task_analytics_with_days(self, db_session: Session, test_user):
        """测试使用days参数获取任务分析"""
        service = AnalyticsService(db_session)
        
        # 创建任务
        task = Task(
            user_id=test_user.id,
            type="screenplay",
            status="pending",
            params={"prompt": "测试"}
        )
        db_session.add(task)
        db_session.commit()
        
        analytics = service.get_task_analytics(user_id=test_user.id, days=7)
        
        assert analytics is not None
        assert "stats" in analytics
        assert "trend" in analytics
    
    def test_get_conversation_analytics_no_data(self, db_session: Session):
        """测试获取空对话分析"""
        service = AnalyticsService(db_session)
        
        analytics = service.get_conversation_analytics()
        
        assert analytics is not None
        assert "stats" in analytics
        assert "trend" in analytics
        assert analytics["stats"]["total_count"] == 0
    
    def test_get_conversation_analytics_with_data(self, db_session: Session, test_user):
        """测试获取有数据的对话分析"""
        service = AnalyticsService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建多个对话
        for i in range(5):
            conv_data = ConversationCreate(title=f"对话{i+1}")
            conv_service.create_conversation(test_user.id, conv_data)
        
        analytics = service.get_conversation_analytics(user_id=test_user.id)
        
        assert analytics is not None
        assert analytics["stats"]["total_count"] >= 5
        assert "trend" in analytics
    
    def test_get_conversation_analytics_with_days(self, db_session: Session, test_user):
        """测试使用days参数获取对话分析"""
        service = AnalyticsService(db_session)
        conv_service = ConversationService(db_session)
        
        # 创建对话
        conv_data = ConversationCreate(title="测试对话")
        conv_service.create_conversation(test_user.id, conv_data)
        
        analytics = service.get_conversation_analytics(user_id=test_user.id, days=7)
        
        assert analytics is not None
        assert "stats" in analytics
        assert "trend" in analytics
    
    def test_get_media_analytics_no_data(self, db_session: Session):
        """测试获取空媒体分析"""
        service = AnalyticsService(db_session)
        
        analytics = service.get_media_analytics()
        
        assert analytics is not None
        assert analytics["image"]["count"] == 0
        assert analytics["video"]["count"] == 0
        assert analytics["total_count"] == 0
        assert analytics["recent_count"] == 0
    
    def test_get_media_analytics_with_images(self, db_session: Session, test_user):
        """测试获取有图片的媒体分析"""
        service = AnalyticsService(db_session)
        
        # 创建任务
        task = Task(
            user_id=test_user.id,
            type="image",
            status="pending",
            params={"prompt": "测试"}
        )
        db_session.add(task)
        db_session.commit()
        db_session.refresh(task)
        
        # 创建多个图片文件
        for i in range(3):
            media = MediaFile(
                user_id=test_user.id,
                type="image",
                storage_path=f"/path/to/image{i}.jpg",
                url=f"https://example.com/image{i}.jpg",
                size=1024000 * (i + 1)  # 1MB, 2MB, 3MB
            )
            db_session.add(media)
        db_session.commit()
        
        analytics = service.get_media_analytics(user_id=test_user.id)
        
        assert analytics is not None
        assert analytics["image"]["count"] == 3
        assert analytics["image"]["total_size_bytes"] > 0
        assert analytics["image"]["total_size_mb"] > 0
        assert analytics["total_count"] == 3
    
    def test_get_media_analytics_with_videos(self, db_session: Session, test_user):
        """测试获取有视频的媒体分析"""
        service = AnalyticsService(db_session)
        
        # 创建任务
        task = Task(
            user_id=test_user.id,
            type="video",
            status="pending",
            params={"prompt": "测试"}
        )
        db_session.add(task)
        db_session.commit()
        db_session.refresh(task)
        
        # 创建多个视频文件
        for i in range(2):
            media = MediaFile(
                user_id=test_user.id,
                type="video",
                storage_path=f"/path/to/video{i}.mp4",
                url=f"https://example.com/video{i}.mp4",
                size=10240000 * (i + 1)  # 10MB, 20MB
            )
            db_session.add(media)
        db_session.commit()
        
        analytics = service.get_media_analytics(user_id=test_user.id)
        
        assert analytics is not None
        assert analytics["video"]["count"] == 2
        assert analytics["video"]["total_size_bytes"] > 0
        assert analytics["video"]["total_size_mb"] > 0
        assert analytics["total_count"] == 2
    
    def test_get_media_analytics_mixed_types(self, db_session: Session, test_user):
        """测试获取混合类型媒体分析"""
        service = AnalyticsService(db_session)
        
        # 创建任务
        image_task = Task(
            user_id=test_user.id,
            type="image",
            status="pending",
            params={"prompt": "图片"}
        )
        video_task = Task(
            user_id=test_user.id,
            type="video",
            status="pending",
            params={"prompt": "视频"}
        )
        db_session.add(image_task)
        db_session.add(video_task)
        db_session.commit()
        db_session.refresh(image_task)
        db_session.refresh(video_task)
        
        # 创建图片和视频
        image = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="/path/to/image.jpg",
            url="https://example.com/image.jpg",
            size=1024000
        )
        video = MediaFile(
            user_id=test_user.id,
            type="video",
            storage_path="/path/to/video.mp4",
            url="https://example.com/video.mp4",
            size=10240000
        )
        db_session.add(image)
        db_session.add(video)
        db_session.commit()
        
        analytics = service.get_media_analytics(user_id=test_user.id)
        
        assert analytics is not None
        assert analytics["image"]["count"] == 1
        assert analytics["video"]["count"] == 1
        assert analytics["total_count"] == 2
    
    def test_get_media_analytics_recent_count(self, db_session: Session, test_user):
        """测试获取最近上传的媒体文件统计"""
        service = AnalyticsService(db_session)
        
        # 创建任务
        task = Task(
            user_id=test_user.id,
            type="image",
            status="pending",
            params={"prompt": "测试"}
        )
        db_session.add(task)
        db_session.commit()
        db_session.refresh(task)
        
        # 创建最近的文件（7天内）
        recent_media = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="/path/to/recent.jpg",
            url="https://example.com/recent.jpg",
            size=1024000,
            created_at=datetime.utcnow() - timedelta(days=3)
        )
        db_session.add(recent_media)
        
        # 创建较旧的文件（超过7天）
        old_media = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="/path/to/old.jpg",
            url="https://example.com/old.jpg",
            size=1024000,
            created_at=datetime.utcnow() - timedelta(days=10)
        )
        db_session.add(old_media)
        db_session.commit()
        
        analytics = service.get_media_analytics(user_id=test_user.id)
        
        assert analytics is not None
        assert analytics["recent_count"] >= 1
        assert analytics["total_count"] >= 2
    
    def test_get_media_analytics_all_users(self, db_session: Session, test_user):
        """测试获取所有用户的媒体分析"""
        service = AnalyticsService(db_session)
        auth_service = AuthService(db_session)
        
        # 创建另一个用户
        other_user_data = UserCreate(
            username="otheruser",
            email="other@example.com",
            password="password123"
        )
        other_user = auth_service.create_user(other_user_data)
        
        # 为两个用户创建任务
        task1 = Task(
            user_id=test_user.id,
            type="image",
            status="pending",
            params={"prompt": "用户1"}
        )
        task2 = Task(
            user_id=other_user.id,
            type="image",
            status="pending",
            params={"prompt": "用户2"}
        )
        db_session.add(task1)
        db_session.add(task2)
        db_session.commit()
        db_session.refresh(task1)
        db_session.refresh(task2)
        
        media1 = MediaFile(
            user_id=test_user.id,
            type="image",
            storage_path="/path/to/user1.jpg",
            url="https://example.com/user1.jpg",
            size=1024000
        )
        media2 = MediaFile(
            user_id=other_user.id,
            type="image",
            storage_path="/path/to/user2.jpg",
            url="https://example.com/user2.jpg",
            size=1024000
        )
        db_session.add(media1)
        db_session.add(media2)
        db_session.commit()
        
        # 获取所有用户的统计
        all_analytics = service.get_media_analytics()
        
        # 获取特定用户的统计
        user_analytics = service.get_media_analytics(user_id=test_user.id)
        
        assert all_analytics["total_count"] >= 2
        assert user_analytics["total_count"] == 1
