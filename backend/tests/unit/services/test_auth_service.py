"""认证服务单元测试"""
import pytest
from sqlalchemy.orm import Session
from shared.models.user import UserCreate
from services.agent_service.src.services.auth_service import AuthService
from shared.utils.exceptions import AuthenticationError


@pytest.mark.unit
class TestAuthService:
    """认证服务测试类"""
    
    def test_create_user_success(self, db_session: Session):
        """测试成功创建用户"""
        service = AuthService(db_session)
        user_data = UserCreate(
            username="newuser",
            email="newuser@example.com",
            password="password123"
        )
        
        user = service.create_user(user_data)
        
        assert user is not None
        assert user.username == "newuser"
        assert user.email == "newuser@example.com"
        assert user.password_hash is not None
        assert user.is_active is True
    
    def test_create_user_duplicate_email(self, db_session: Session, test_user):
        """测试创建重复邮箱用户失败"""
        service = AuthService(db_session)
        user_data = UserCreate(
            username="anotheruser",
            email=test_user.email,  # 使用已存在的邮箱
            password="password123"
        )
        
        with pytest.raises(ValueError, match="邮箱已被注册"):
            service.create_user(user_data)
    
    def test_create_user_duplicate_username(self, db_session: Session, test_user):
        """测试创建重复用户名用户失败"""
        service = AuthService(db_session)
        user_data = UserCreate(
            username=test_user.username,  # 使用已存在的用户名
            email="another@example.com",
            password="password123"
        )
        
        with pytest.raises(ValueError, match="用户名已被使用"):
            service.create_user(user_data)
    
    def test_get_user_by_email(self, db_session: Session, test_user):
        """测试根据邮箱获取用户"""
        service = AuthService(db_session)
        user = service.get_user_by_email(test_user.email)
        
        assert user is not None
        assert user.email == test_user.email
        assert user.username == test_user.username
    
    def test_get_user_by_email_not_found(self, db_session: Session):
        """测试获取不存在的用户"""
        service = AuthService(db_session)
        user = service.get_user_by_email("nonexistent@example.com")
        
        assert user is None
    
    def test_get_user_by_username(self, db_session: Session, test_user):
        """测试根据用户名获取用户"""
        service = AuthService(db_session)
        user = service.get_user_by_username(test_user.username)
        
        assert user is not None
        assert user.username == test_user.username
        assert user.email == test_user.email
    
    def test_get_user_by_id(self, db_session: Session, test_user):
        """测试根据ID获取用户"""
        service = AuthService(db_session)
        user = service.get_user_by_id(str(test_user.id))
        
        assert user is not None
        assert user.id == test_user.id
    
    def test_get_user_by_id_invalid(self, db_session: Session):
        """测试使用无效ID获取用户"""
        service = AuthService(db_session)
        user = service.get_user_by_id("invalid-uuid")
        
        assert user is None
    
    def test_verify_password(self, db_session: Session, test_user_data):
        """测试密码验证"""
        service = AuthService(db_session)
        user_data = UserCreate(**test_user_data)
        user = service.create_user(user_data)
        
        # 验证正确密码
        assert service.verify_password(test_user_data["password"], user.password_hash) is True
        
        # 验证错误密码
        assert service.verify_password("wrongpassword", user.password_hash) is False
