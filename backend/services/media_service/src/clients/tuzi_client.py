import httpx
import os
from typing import Dict, Any, Optional
import asyncio

class TuziClient:
    """Tuzi API 客户端（视频生成）"""
    
    def __init__(self):
        self.base_url = "https://api.ourzhishi.top"
        self.api_key = os.getenv("TUZI_API_KEY")
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=300.0,
            headers={
                "Authorization": f"Bearer {self.api_key}"
            }
        )
    
    async def generate_video(
        self,
        prompt: str,
        image_url: Optional[str] = None,
        seconds: str = "10",
        model: str = "sora-1",
        reference_images: Optional[list] = None
    ) -> Dict[str, Any]:
        """生成视频"""
        data = {
            "model": model,
            "prompt": prompt,
            "seconds": seconds
        }
        
        files = {}
        if image_url:
            data["input_reference"] = image_url
        
        if reference_images:
            for i, img_url in enumerate(reference_images):
                data[f"input_reference_{i}"] = img_url
        
        response = await self.client.post(
            "/v1/videos",
            data=data,
            files=files
        )
        response.raise_for_status()
        return response.json()
    
    async def get_video_status(self, task_id: str) -> Dict[str, Any]:
        """获取视频生成状态"""
        response = await self.client.get(f"/v1/videos/{task_id}")
        response.raise_for_status()
        return response.json()
    
    async def wait_for_video(
        self,
        task_id: str,
        max_wait_time: int = 300,
        poll_interval: int = 5
    ) -> Dict[str, Any]:
        """等待视频生成完成"""
        start_time = asyncio.get_event_loop().time()
        
        while True:
            status = await self.get_video_status(task_id)
            
            if status.get("status") == "completed":
                return status
            
            if status.get("status") == "failed":
                raise Exception(f"视频生成失败: {status.get('error')}")
            
            elapsed = asyncio.get_event_loop().time() - start_time
            if elapsed > max_wait_time:
                raise TimeoutError("视频生成超时")
            
            await asyncio.sleep(poll_interval)
    
    async def close(self):
        """关闭客户端"""
        await self.client.aclose()
