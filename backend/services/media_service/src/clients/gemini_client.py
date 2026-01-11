import httpx
from typing import Dict, Any, Optional, List

class GeminiClient:
    """Gemini API 客户端（图片生成）"""
    
    def __init__(self, api_key: str):
        """
        初始化客户端
        
        Args:
            api_key: 用户提供的Gemini API密钥
        """
        if not api_key:
            raise ValueError("Gemini API密钥不能为空")
        
        self.base_url = "https://api.ourzhishi.top"
        self.api_key = api_key
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=120.0,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
        )
    
    async def generate_image(
        self,
        prompt: str,
        model: str = "gemini-3-pro-image-preview-hd",
        size: str = "1024x1024",
        reference_images: Optional[List[str]] = None
    ) -> Dict[str, Any]:
        """生成图片"""
        payload = {
            "model": model,
            "prompt": prompt,
            "size": size,
            "response_format": "url",
            "n": 1
        }
        
        if reference_images:
            payload["image"] = reference_images
        
        response = await self.client.post(
            "/v1/images/generations",
            json=payload
        )
        response.raise_for_status()
        return response.json()
    
    async def close(self):
        """关闭客户端"""
        await self.client.aclose()
