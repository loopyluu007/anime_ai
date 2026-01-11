import httpx
from typing import Dict, Any, Optional
import json

class GLMClient:
    """智谱 GLM API 客户端"""
    
    def __init__(self, api_key: str):
        """
        初始化客户端
        
        Args:
            api_key: 用户提供的GLM API密钥
        """
        if not api_key:
            raise ValueError("GLM API密钥不能为空")
        
        self.base_url = "https://open.bigmodel.cn/api/paas/v4"
        self.api_key = api_key
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=60.0,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
        )
    
    async def chat_completion(
        self,
        messages: list,
        model: str = "glm-4",
        temperature: float = 0.7,
        stream: bool = False
    ) -> Dict[str, Any]:
        """聊天补全"""
        response = await self.client.post(
            "/chat/completions",
            json={
                "model": model,
                "messages": messages,
                "temperature": temperature,
                "stream": stream
            }
        )
        response.raise_for_status()
        return response.json()
    
    async def generate_screenplay(
        self,
        user_prompt: str,
        user_images: Optional[list] = None,
        scene_count: int = 7,
        character_count: int = 2
    ) -> Dict[str, Any]:
        """生成剧本"""
        system_prompt = self._build_screenplay_system_prompt(scene_count, character_count)
        
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
        
        # 如果有用户上传的图片，添加到消息中
        if user_images:
            content = [{"type": "text", "text": user_prompt}]
            for img in user_images:
                content.append({
                    "type": "image_url",
                    "image_url": {"url": f"data:image/jpeg;base64,{img}"}
                })
            messages[1]["content"] = content
        
        response = await self.chat_completion(messages, model="glm-4")
        
        # 解析 JSON 响应
        content = response["choices"][0]["message"]["content"]
        screenplay_data = json.loads(content)
        
        return screenplay_data
    
    def _build_screenplay_system_prompt(self, scene_count: int, character_count: int) -> str:
        """构建剧本生成系统提示词"""
        return f"""You are DirectorAI, a SCREENPLAY CREATION AGENT for short video production.

YOUR MISSION: Convert user's creative idea into a multi-scene screenplay with exactly {scene_count} scenes.
Each scene will be turned into: Narration (Chinese) → Image → Video.

CRITICAL OUTPUT FORMAT:
You MUST respond with ONLY a valid JSON object. No markdown, no explanations, no thinking process.

JSON SCHEMA:
{{
  "task_id": "unique_task_id",
  "script_title": "剧本标题",
  "scenes": [
    {{
      "scene_id": 1,
      "narration": "中文旁白，描述这一幕的内容",
      "image_prompt": "Detailed English visual description for image generation",
      "video_prompt": "English motion/description for video animation",
      "character_description": "Detailed character description for consistency across scenes",
      "image_url": null,
      "video_url": null,
      "status": "pending"
    }}
  ],
  "characters": [
    {{
      "name": "角色名称",
      "description": "角色描述"
    }}
  ]
}}

GUIDELINES:
1. NUMBER OF SCENES: EXACTLY {scene_count} SCENES
2. CHARACTER CONSISTENCY: First scene's image_prompt MUST contain detailed character appearance
3. NARRATION: Short, evocative descriptions in Chinese (1-2 sentences per scene)
4. IMAGE_PROMPT: Always start with "anime style, manga art, 2D animation, cel shaded"
5. VIDEO_PROMPT: Motion description in English
"""
    
    async def close(self):
        """关闭客户端"""
        await self.client.aclose()
