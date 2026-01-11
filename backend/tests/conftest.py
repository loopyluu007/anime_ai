"""pytest配置和共享fixtures"""
import pytest
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from fastapi.testclient import TestClient
from typing import Generator

# 设置测试环境变量（必须在导入其他模块之前）
os.environ["TESTING"] = "true"
os.environ["SECRET_KEY"] = "test-secret-key-for-testing-only"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["REDIS_URL"] = "redis://localhost:6379/0"
os.environ["ACCESS_TOKEN_EXPIRE_MINUTES"] = "60"

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import Base, get_db
# 在测试环境中，暂时只导入User模型用于认证测试
# 注意：Message和MediaFile模型有metadata字段，与SQLAlchemy保留字冲突
# 暂时只导入需要的模型
from shared.models.db_models import User
# 延迟导入app，避免导入时触发有问题的模型


@pytest.fixture(scope="function")
def db_session():
    """创建测试数据库会话"""
    # 使用SQLite内存数据库进行测试
    # 注意：SQLite不支持PostgreSQL的UUID类型，需要特殊处理
    from sqlalchemy import event, String
    from sqlalchemy.engine import Engine
    from sqlalchemy.dialects.postgresql import UUID as PG_UUID
    import uuid
    
    # 为SQLite启用外键支持
    @event.listens_for(Engine, "connect")
    def set_sqlite_pragma(dbapi_conn, connection_record):
        cursor = dbapi_conn.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()
    
    # 创建引擎
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    
    # 将PostgreSQL UUID类型映射为String类型以支持SQLite
    # 这需要在创建表之前完成
    from sqlalchemy import MetaData
    from shared.models.db_models import User, Conversation, Message, Task, Screenplay, Scene, CharacterSheet, MediaFile, TaskLog
    
    # 创建一个新的metadata用于测试，将UUID转换为String
    test_metadata = MetaData()
    
    # 重新定义表结构，将UUID改为String
    # 这里我们直接使用原始模型，但SQLAlchemy会在SQLite中自动处理
    # 如果遇到问题，可以手动创建兼容的表结构
    
    # 创建所有表（SQLAlchemy会尝试适配）
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as e:
        # 如果UUID类型导致问题，我们需要手动处理
        # 暂时先尝试运行，看看实际错误
        print(f"Warning: Table creation issue: {e}")
        # 继续执行，让测试显示具体错误
    
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    session = TestingSessionLocal()
    try:
        yield session
    finally:
        session.close()
        try:
            Base.metadata.drop_all(bind=engine)
        except:
            pass  # 忽略清理错误


@pytest.fixture(scope="function")
def client(db_session):
    """创建测试客户端"""
    # 延迟导入app，避免导入时触发有问题的模型
    from services.agent_service.src.main import app
    
    def override_get_db():
        try:
            yield db_session
        finally:
            pass
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as test_client:
        yield test_client
    
    app.dependency_overrides.clear()


@pytest.fixture
def test_user_data():
    """测试用户数据"""
    return {
        "username": "testuser",
        "email": "test@example.com",
        "password": "testpassword123"
    }


@pytest.fixture
def test_user(db_session, test_user_data):
    """创建测试用户"""
    import bcrypt
    
    password_bytes = test_user_data["password"].encode('utf-8')
    hashed_password = bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode('utf-8')
    
    user = User(
        username=test_user_data["username"],
        email=test_user_data["email"],
        password_hash=hashed_password,
        is_active=True
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture
def auth_headers(client, test_user_data):
    """获取认证headers"""
    # 先注册用户
    response = client.post(
        "/api/v1/auth/register",
        json=test_user_data
    )
    
    # 然后登录获取token
    response = client.post(
        "/api/v1/auth/login",
        data={
            "username": test_user_data["email"],
            "password": test_user_data["password"]
        }
    )
    
    token = response.json()["data"]["access_token"]
    return {"Authorization": f"Bearer {token}"}
