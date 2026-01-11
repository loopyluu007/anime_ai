"""媒体生成API集成测试"""
import pytest
from fastapi import status
from uuid import uuid4


@pytest.mark.integration
@pytest.mark.api
class TestImagesAPI:
    """图片生成API测试类"""
    
    def test_create_image_generation_task(self, client, auth_headers):
        """测试创建图片生成任务"""
        image_data = {
            "prompt": "一只可爱的小猫在花园里玩耍",
            "model": "gemini-3-pro-image-preview",
            "size": "1024x1024"
        }
        
        response = client.post(
            "/api/v1/media/images/generate",
            json=image_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert "taskId" in data["data"]
        assert "status" in data["data"]
    
    def test_create_image_generation_task_with_reference(self, client, auth_headers):
        """测试创建带参考图片的生成任务"""
        image_data = {
            "prompt": "基于参考图片生成相似风格的图片",
            "model": "gemini-3-pro-image-preview",
            "size": "1024x1024",
            "referenceImages": [
                "https://example.com/reference1.jpg",
                "https://example.com/reference2.jpg"
            ]
        }
        
        response = client.post(
            "/api/v1/media/images/generate",
            json=image_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "taskId" in data["data"]
    
    def test_get_image_not_found(self, client, auth_headers):
        """测试获取不存在的图片"""
        fake_id = str(uuid4())
        
        response = client.get(
            f"/api/v1/media/images/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_create_image_requires_auth(self, client):
        """测试创建图片生成任务需要认证"""
        response = client.post(
            "/api/v1/media/images/generate",
            json={
                "prompt": "测试图片",
                "model": "gemini-3-pro-image-preview",
                "size": "1024x1024"
            }
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.integration
@pytest.mark.api
class TestVideosAPI:
    """视频生成API测试类"""
    
    def test_create_video_generation_task(self, client, auth_headers):
        """测试创建视频生成任务"""
        video_data = {
            "prompt": "一只小猫在草地上奔跑",
            "model": "tuzi-3.1",
            "imageUrl": "https://example.com/image.jpg",
            "seconds": 5
        }
        
        response = client.post(
            "/api/v1/media/videos/generate",
            json=video_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert "taskId" in data["data"]
        assert "status" in data["data"]
    
    def test_create_video_generation_task_with_image_id(self, client, auth_headers):
        """测试使用图片ID创建视频生成任务"""
        video_data = {
            "prompt": "基于图片生成视频",
            "model": "tuzi-3.1",
            "imageId": str(uuid4()),
            "seconds": 10
        }
        
        response = client.post(
            "/api/v1/media/videos/generate",
            json=video_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "taskId" in data["data"]
    
    def test_create_video_with_reference_images(self, client, auth_headers):
        """测试创建带参考图片的视频生成任务"""
        video_data = {
            "prompt": "生成连贯动作的视频",
            "model": "tuzi-3.1",
            "imageUrl": "https://example.com/image.jpg",
            "seconds": 5,
            "referenceImages": [
                "https://example.com/ref1.jpg",
                "https://example.com/ref2.jpg"
            ]
        }
        
        response = client.post(
            "/api/v1/media/videos/generate",
            json=video_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "taskId" in data["data"]
    
    def test_get_video_not_found(self, client, auth_headers):
        """测试获取不存在的视频"""
        fake_id = str(uuid4())
        
        response = client.get(
            f"/api/v1/media/videos/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_create_video_requires_auth(self, client):
        """测试创建视频生成任务需要认证"""
        response = client.post(
            "/api/v1/media/videos/generate",
            json={
                "prompt": "测试视频",
                "model": "tuzi-3.1",
                "imageUrl": "https://example.com/image.jpg",
                "seconds": 5
            }
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
    
    def test_create_video_missing_required_fields(self, client, auth_headers):
        """测试创建视频任务缺少必需字段"""
        # 缺少imageUrl和imageId
        video_data = {
            "prompt": "测试视频",
            "model": "tuzi-3.1",
            "seconds": 5
        }
        
        response = client.post(
            "/api/v1/media/videos/generate",
            json=video_data,
            headers=auth_headers
        )
        
        # 应该返回400或422（取决于验证逻辑）
        assert response.status_code in [
            status.HTTP_400_BAD_REQUEST,
            status.HTTP_422_UNPROCESSABLE_ENTITY
        ]
