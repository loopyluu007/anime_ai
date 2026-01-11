from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://user:password@localhost:5432/directorai"
)

# 延迟创建engine，避免在测试环境中导入时立即连接数据库
_engine = None
_SessionLocal = None

def get_engine():
    """获取数据库引擎（延迟创建）"""
    global _engine
    if _engine is None:
        # 在测试环境中，如果使用SQLite，不需要psycopg2
        if os.getenv("TESTING") == "true" and DATABASE_URL.startswith("sqlite"):
            # 测试环境使用SQLite，不需要创建engine（由测试fixture创建）
            return None
        _engine = create_engine(DATABASE_URL, pool_pre_ping=True)
    return _engine

def get_session_local():
    """获取SessionLocal（延迟创建）"""
    global _SessionLocal
    if _SessionLocal is None:
        engine = get_engine()
        if engine is None:
            # 测试环境，返回None，由测试fixture处理
            return None
        _SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    return _SessionLocal

# 为了向后兼容，仍然创建这些变量，但在测试环境中它们可能是None
try:
    engine = get_engine()
    SessionLocal = get_session_local()
except Exception:
    # 如果无法连接数据库（如测试环境），设置为None
    engine = None
    SessionLocal = None

Base = declarative_base()

def get_db():
    """获取数据库会话"""
    # 在测试环境中，这个函数会被override，所以这里只是占位
    if SessionLocal is None:
        # 测试环境，应该由测试fixture提供db
        raise RuntimeError("Database not initialized. Use test fixtures in test environment.")
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
