from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from uuid import UUID

import sys
from pathlib import Path

# 添加backend目录到路径
backend_path = Path(__file__).parent.parent.parent.parent.parent
sys.path.insert(0, str(backend_path))

from shared.config.database import get_db
from shared.models.screenplay import ScreenplayDraft, ScreenplayConfirm, ScreenplayUpdate, ScreenplayResponse
from services.agent_service.src.services.screenplay_service import ScreenplayService
from services.agent_service.src.api.auth import get_current_user

router = APIRouter(prefix="/screenplays", tags=["剧本"])

@router.post("/draft", response_model=dict)
async def create_screenplay_draft(
    draft_data: ScreenplayDraft,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """生成剧本草稿"""
    service = ScreenplayService(db)
    
    try:
        screenplay = await service.create_draft(
            user_id=current_user.id,
            task_id=draft_data.task_id,
            prompt=draft_data.prompt,
            user_images=draft_data.user_images,
            scene_count=draft_data.scene_count,
            character_count=draft_data.character_count
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    # 构建响应数据
    scenes_data = []
    for scene in screenplay.scenes:
        scenes_data.append({
            "sceneId": scene.scene_id,
            "narration": scene.narration,
            "imagePrompt": scene.image_prompt,
            "videoPrompt": scene.video_prompt,
            "status": scene.status
        })
    
    character_sheets_data = []
    for char_sheet in screenplay.character_sheets:
        character_sheets_data.append({
            "id": str(char_sheet.id),
            "name": char_sheet.name,
            "description": char_sheet.description,
            "combinedViewUrl": char_sheet.combined_view_url
        })
    
    return {
        "code": 200,
        "message": "剧本草稿生成成功",
        "data": {
            "id": str(screenplay.id),
            "taskId": str(screenplay.task_id),
            "title": screenplay.title,
            "status": screenplay.status,
            "scenes": scenes_data,
            "characterSheets": character_sheets_data
        }
    }

@router.post("/{screenplay_id}/confirm", response_model=dict)
async def confirm_screenplay(
    screenplay_id: UUID,
    confirm_data: ScreenplayConfirm,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """确认剧本"""
    service = ScreenplayService(db)
    
    try:
        screenplay = service.confirm_screenplay(
            screenplay_id=screenplay_id,
            user_id=current_user.id,
            feedback=confirm_data.feedback
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
    if not screenplay:
        raise HTTPException(status_code=404, detail="剧本不存在")
    
    return {
        "code": 200,
        "message": "剧本确认成功",
        "data": {
            "id": str(screenplay.id),
            "status": screenplay.status,
            "taskId": str(screenplay.task_id)
        }
    }

@router.get("/{screenplay_id}", response_model=dict)
async def get_screenplay(
    screenplay_id: UUID,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """获取剧本详情"""
    service = ScreenplayService(db)
    screenplay = service.get_screenplay(screenplay_id, current_user.id)
    
    if not screenplay:
        raise HTTPException(status_code=404, detail="剧本不存在")
    
    # 构建响应数据
    scenes_data = []
    for scene in screenplay.scenes:
        scenes_data.append({
            "sceneId": scene.scene_id,
            "narration": scene.narration,
            "imagePrompt": scene.image_prompt,
            "videoPrompt": scene.video_prompt,
            "imageUrl": scene.image_url,
            "videoUrl": scene.video_url,
            "status": scene.status
        })
    
    character_sheets_data = []
    for char_sheet in screenplay.character_sheets:
        character_sheets_data.append({
            "id": str(char_sheet.id),
            "name": char_sheet.name,
            "description": char_sheet.description,
            "combinedViewUrl": char_sheet.combined_view_url,
            "frontViewUrl": char_sheet.front_view_url,
            "sideViewUrl": char_sheet.side_view_url,
            "backViewUrl": char_sheet.back_view_url
        })
    
    return {
        "code": 200,
        "data": {
            "id": str(screenplay.id),
            "title": screenplay.title,
            "status": screenplay.status,
            "scenes": scenes_data,
            "characterSheets": character_sheets_data,
            "createdAt": screenplay.created_at.isoformat(),
            "updatedAt": screenplay.updated_at.isoformat()
        }
    }

@router.put("/{screenplay_id}", response_model=dict)
async def update_screenplay(
    screenplay_id: UUID,
    update_data: ScreenplayUpdate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """更新剧本"""
    service = ScreenplayService(db)
    screenplay = service.update_screenplay(
        screenplay_id=screenplay_id,
        user_id=current_user.id,
        title=update_data.title
    )
    
    if not screenplay:
        raise HTTPException(status_code=404, detail="剧本不存在")
    
    return {
        "code": 200,
        "message": "更新成功",
        "data": {
            "id": str(screenplay.id),
            "title": screenplay.title,
            "status": screenplay.status
        }
    }