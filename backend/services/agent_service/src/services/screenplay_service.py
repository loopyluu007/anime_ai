from sqlalchemy.orm import Session, joinedload
from uuid import UUID
from typing import Optional, Dict, Any
from datetime import datetime

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.models.db_models import Screenplay, Scene, CharacterSheet, Task
from shared.models.screenplay import ScreenplayStatus, SceneStatus
from services.agent_service.src.clients.glm_client import GLMClient
from services.agent_service.src.services.task_service import TaskService, TaskStatus

class ScreenplayService:
    """剧本服务"""
    
    def __init__(self, db: Session):
        self.db = db
        self.glm_client = GLMClient()
        self.task_service = TaskService(db)
    
    async def create_draft(
        self,
        user_id: UUID,
        task_id: UUID,
        prompt: str,
        user_images: Optional[list] = None,
        scene_count: int = 7,
        character_count: int = 2
    ) -> Screenplay:
        """生成剧本草稿"""
        # 验证任务是否存在且属于用户
        task = self.db.query(Task).filter(
            Task.id == task_id,
            Task.user_id == user_id
        ).first()
        
        if not task:
            raise ValueError("任务不存在")
        
        # 调用GLM客户端生成剧本
        screenplay_data = await self.glm_client.generate_screenplay(
            user_prompt=prompt,
            user_images=user_images,
            scene_count=scene_count,
            character_count=character_count
        )
        
        # 创建剧本记录
        screenplay = Screenplay(
            task_id=task_id,
            user_id=user_id,
            title=screenplay_data.get("script_title", "未命名剧本"),
            status=ScreenplayStatus.DRAFT.value
        )
        
        self.db.add(screenplay)
        self.db.flush()  # 获取ID
        
        # 创建场景记录
        scenes_data = screenplay_data.get("scenes", [])
        for scene_data in scenes_data:
            scene = Scene(
                screenplay_id=screenplay.id,
                scene_id=scene_data["scene_id"],
                narration=scene_data["narration"],
                image_prompt=scene_data["image_prompt"],
                video_prompt=scene_data["video_prompt"],
                character_description=scene_data.get("character_description"),
                status=SceneStatus.PENDING.value
            )
            self.db.add(scene)
        
        # 创建角色表记录
        characters_data = screenplay_data.get("characters", [])
        for char_data in characters_data:
            character_sheet = CharacterSheet(
                screenplay_id=screenplay.id,
                name=char_data["name"],
                description=char_data.get("description")
            )
            self.db.add(character_sheet)
        
        self.db.commit()
        self.db.refresh(screenplay)
        
        # 更新任务状态
        self.task_service.update_task_status(
            task_id=task_id,
            status=TaskStatus.COMPLETED,
            progress=100,
            result={"screenplay_id": str(screenplay.id)}
        )
        
        return screenplay
    
    def get_screenplay(self, screenplay_id: UUID, user_id: UUID) -> Optional[Screenplay]:
        """获取剧本详情"""
        return self.db.query(Screenplay).options(
            joinedload(Screenplay.scenes),
            joinedload(Screenplay.character_sheets)
        ).filter(
            Screenplay.id == screenplay_id,
            Screenplay.user_id == user_id
        ).first()
    
    def confirm_screenplay(
        self,
        screenplay_id: UUID,
        user_id: UUID,
        feedback: Optional[str] = None
    ) -> Optional[Screenplay]:
        """确认剧本"""
        screenplay = self.get_screenplay(screenplay_id, user_id)
        if not screenplay:
            return None
        
        if screenplay.status != ScreenplayStatus.DRAFT.value:
            raise ValueError("只能确认草稿状态的剧本")
        
        # 更新状态为生成中
        screenplay.status = ScreenplayStatus.GENERATING.value
        screenplay.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(screenplay)
        
        # 更新任务状态
        self.task_service.update_task_status(
            task_id=screenplay.task_id,
            status=TaskStatus.PROCESSING,
            progress=0
        )
        
        return screenplay
    
    def update_screenplay(
        self,
        screenplay_id: UUID,
        user_id: UUID,
        title: Optional[str] = None
    ) -> Optional[Screenplay]:
        """更新剧本"""
        screenplay = self.get_screenplay(screenplay_id, user_id)
        if not screenplay:
            return None
        
        if title is not None:
            screenplay.title = title
        
        screenplay.updated_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(screenplay)
        
        return screenplay