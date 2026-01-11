from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid
from shared.config.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String(50), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    avatar_url = Column(Text)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    conversations = relationship("Conversation", back_populates="user", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="user", cascade="all, delete-orphan")

class Conversation(Base):
    __tablename__ = "conversations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    preview_text = Column(Text)
    message_count = Column(Integer, default=0)
    is_pinned = Column(Boolean, default=False)
    last_accessed_at = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="conversation")

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    role = Column(String(20), nullable=False)
    content = Column(Text, nullable=False)
    type = Column(String(20), default="text")
    # 使用meta_data作为属性名，数据库列名为metadata，避免与SQLAlchemy的metadata保留字冲突
    # 注意：需要在类定义完成后添加metadata属性作为兼容层
    meta_data = Column("metadata", JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    conversation = relationship("Conversation", back_populates="messages")

# 在类定义完成后添加metadata属性作为兼容层
# 使用setattr避免在类定义时触发SQLAlchemy的检查
def _get_metadata(self):
    return self.meta_data

def _set_metadata(self, value):
    self.meta_data = value

Message.metadata = property(_get_metadata, _set_metadata)

class Task(Base):
    __tablename__ = "tasks"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("conversations.id", ondelete="SET NULL"))
    type = Column(String(50), nullable=False)
    status = Column(String(20), default="pending")
    progress = Column(Integer, default=0)
    params = Column(JSON)
    result = Column(JSON)
    error_message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    completed_at = Column(DateTime)
    
    user = relationship("User", back_populates="tasks")
    conversation = relationship("Conversation", back_populates="tasks")
    screenplay = relationship("Screenplay", back_populates="task", uselist=False)

class Screenplay(Base):
    __tablename__ = "screenplays"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    task_id = Column(UUID(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    status = Column(String(20), default="draft")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    task = relationship("Task", back_populates="screenplay")
    scenes = relationship("Scene", back_populates="screenplay", cascade="all, delete-orphan")
    character_sheets = relationship("CharacterSheet", back_populates="screenplay", cascade="all, delete-orphan")

class Scene(Base):
    __tablename__ = "scenes"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    screenplay_id = Column(UUID(as_uuid=True), ForeignKey("screenplays.id", ondelete="CASCADE"), nullable=False)
    scene_id = Column(Integer, nullable=False)
    narration = Column(Text, nullable=False)
    image_prompt = Column(Text, nullable=False)
    video_prompt = Column(Text, nullable=False)
    character_description = Column(Text)
    image_url = Column(Text)
    video_url = Column(Text)
    status = Column(String(20), default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    screenplay = relationship("Screenplay", back_populates="scenes")
    
    # 使用UniqueConstraint以支持多数据库
    from sqlalchemy import UniqueConstraint
    __table_args__ = (
        UniqueConstraint("screenplay_id", "scene_id", name="uq_scene_screenplay_scene"),
    )

class CharacterSheet(Base):
    __tablename__ = "character_sheets"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    screenplay_id = Column(UUID(as_uuid=True), ForeignKey("screenplays.id", ondelete="CASCADE"), nullable=False)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    combined_view_url = Column(Text)
    front_view_url = Column(Text)
    side_view_url = Column(Text)
    back_view_url = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    screenplay = relationship("Screenplay", back_populates="character_sheets")

class MediaFile(Base):
    __tablename__ = "media_files"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    type = Column(String(20), nullable=False)
    original_filename = Column(String(255))
    storage_path = Column(Text, nullable=False)
    url = Column(Text, nullable=False)
    mime_type = Column(String(100))
    size = Column(Integer)
    width = Column(Integer)
    height = Column(Integer)
    duration = Column(Integer)
    # 使用meta_data作为属性名，数据库列名为metadata，避免与SQLAlchemy的metadata保留字冲突
    meta_data = Column("metadata", JSON)
    created_at = Column(DateTime, default=datetime.utcnow)

# 在类定义完成后添加metadata属性作为兼容层
def _get_media_metadata(self):
    return self.meta_data

def _set_media_metadata(self, value):
    self.meta_data = value

MediaFile.metadata = property(_get_media_metadata, _set_media_metadata)

class TaskLog(Base):
    __tablename__ = "task_logs"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    task_id = Column(UUID(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False)
    level = Column(String(20), nullable=False)
    message = Column(Text, nullable=False)
    details = Column(JSON)
    created_at = Column(DateTime, default=datetime.utcnow)
