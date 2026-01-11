from sqlalchemy.orm import Session
from uuid import UUID
import bcrypt
from shared.models.db_models import User
from shared.models.user import UserCreate

class AuthService:
    """认证服务"""
    
    def __init__(self, db: Session):
        self.db = db
    
    def get_user_by_email(self, email: str) -> User:
        """根据邮箱获取用户"""
        return self.db.query(User).filter(User.email == email).first()
    
    def get_user_by_id(self, user_id: str) -> User:
        """根据ID获取用户"""
        try:
            uuid_id = UUID(user_id)
            return self.db.query(User).filter(User.id == uuid_id).first()
        except (ValueError, TypeError):
            return None
    
    def get_user_by_username(self, username: str) -> User:
        """根据用户名获取用户"""
        return self.db.query(User).filter(User.username == username).first()
    
    def create_user(self, user_data: UserCreate) -> User:
        """创建用户"""
        # 检查邮箱是否已存在
        if self.get_user_by_email(user_data.email):
            raise ValueError("邮箱已被注册")
        
        # 检查用户名是否已存在
        if self.get_user_by_username(user_data.username):
            raise ValueError("用户名已被使用")
        
        # 创建用户
        # 使用bcrypt直接哈希密码，避免passlib的兼容性问题
        password_bytes = user_data.password.encode('utf-8')
        hashed_password = bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode('utf-8')
        user = User(
            username=user_data.username,
            email=user_data.email,
            password_hash=hashed_password,
            is_active=True
        )
        
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        
        return user
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """验证密码"""
        # 使用bcrypt直接验证密码
        password_bytes = plain_password.encode('utf-8')
        hash_bytes = hashed_password.encode('utf-8')
        return bcrypt.checkpw(password_bytes, hash_bytes)
