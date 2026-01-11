"""任务和剧本API集成测试"""
import pytest
from fastapi import status
from uuid import uuid4


@pytest.mark.integration
@pytest.mark.api
class TestTasksAPI:
    """任务API测试类"""
    
    def test_create_task_success(self, client, auth_headers):
        """测试成功创建任务"""
        task_data = {
            "type": "screenplay",
            "description": "测试任务"
        }
        
        response = client.post(
            "/api/v1/tasks",
            json=task_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert data["data"]["type"] == task_data["type"]
        assert "id" in data["data"]
    
    def test_get_tasks_list(self, client, auth_headers):
        """测试获取任务列表"""
        # 先创建几个任务
        for i in range(3):
            client.post(
                "/api/v1/tasks",
                json={
                    "type": "screenplay",
                    "description": f"任务 {i+1}"
                },
                headers=auth_headers
            )
        
        # 获取任务列表
        response = client.get(
            "/api/v1/tasks?page=1&pageSize=10",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert "items" in data["data"]
        assert len(data["data"]["items"]) >= 3
    
    def test_get_task_detail(self, client, auth_headers):
        """测试获取任务详情"""
        # 先创建任务
        create_response = client.post(
            "/api/v1/tasks",
            json={
                "type": "screenplay",
                "description": "测试任务详情"
            },
            headers=auth_headers
        )
        task_id = create_response.json()["data"]["id"]
        
        # 获取任务详情
        response = client.get(
            f"/api/v1/tasks/{task_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["id"] == task_id
        assert data["data"]["type"] == "screenplay"
    
    def test_get_task_not_found(self, client, auth_headers):
        """测试获取不存在的任务"""
        fake_id = str(uuid4())
        
        response = client.get(
            f"/api/v1/tasks/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_get_task_progress(self, client, auth_headers):
        """测试获取任务进度"""
        # 先创建任务
        create_response = client.post(
            "/api/v1/tasks",
            json={
                "type": "screenplay",
                "description": "测试任务进度"
            },
            headers=auth_headers
        )
        task_id = create_response.json()["data"]["id"]
        
        # 获取任务进度
        response = client.get(
            f"/api/v1/tasks/{task_id}/progress",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert "progress" in data["data"]
    
    def test_get_tasks_requires_auth(self, client):
        """测试获取任务列表需要认证"""
        response = client.get("/api/v1/tasks")
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.integration
@pytest.mark.api
class TestScreenplaysAPI:
    """剧本API测试类"""
    
    def test_create_screenplay_draft_success(self, client, auth_headers):
        """测试成功创建剧本草稿"""
        # 先创建任务
        task_response = client.post(
            "/api/v1/tasks",
            json={
                "type": "screenplay",
                "description": "测试剧本任务"
            },
            headers=auth_headers
        )
        task_id = task_response.json()["data"]["id"]
        
        # 创建剧本草稿
        draft_data = {
            "taskId": task_id,
            "prompt": "创建一个关于冒险的故事",
            "sceneCount": 3,
            "characterCount": 2
        }
        
        response = client.post(
            "/api/v1/screenplays/draft",
            json=draft_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert data["data"]["taskId"] == task_id
        assert "scenes" in data["data"]
        assert "characterSheets" in data["data"]
    
    def test_confirm_screenplay(self, client, auth_headers):
        """测试确认剧本"""
        # 先创建任务和剧本草稿
        task_response = client.post(
            "/api/v1/tasks",
            json={
                "type": "screenplay",
                "description": "测试剧本确认"
            },
            headers=auth_headers
        )
        task_id = task_response.json()["data"]["id"]
        
        draft_response = client.post(
            "/api/v1/screenplays/draft",
            json={
                "taskId": task_id,
                "prompt": "测试故事",
                "sceneCount": 2,
                "characterCount": 1
            },
            headers=auth_headers
        )
        screenplay_id = draft_response.json()["data"]["id"]
        
        # 确认剧本
        confirm_data = {
            "feedback": "同意此剧本"
        }
        
        response = client.post(
            f"/api/v1/screenplays/{screenplay_id}/confirm",
            json=confirm_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["status"] == "confirmed"
    
    def test_get_screenplay_detail(self, client, auth_headers):
        """测试获取剧本详情"""
        # 先创建任务和剧本草稿
        task_response = client.post(
            "/api/v1/tasks",
            json={
                "type": "screenplay",
                "description": "测试剧本详情"
            },
            headers=auth_headers
        )
        task_id = task_response.json()["data"]["id"]
        
        draft_response = client.post(
            "/api/v1/screenplays/draft",
            json={
                "taskId": task_id,
                "prompt": "测试故事",
                "sceneCount": 2,
                "characterCount": 1
            },
            headers=auth_headers
        )
        screenplay_id = draft_response.json()["data"]["id"]
        
        # 获取剧本详情
        response = client.get(
            f"/api/v1/screenplays/{screenplay_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["id"] == screenplay_id
    
    def test_update_screenplay(self, client, auth_headers):
        """测试更新剧本"""
        # 先创建任务和剧本草稿
        task_response = client.post(
            "/api/v1/tasks",
            json={
                "type": "screenplay",
                "description": "测试剧本更新"
            },
            headers=auth_headers
        )
        task_id = task_response.json()["data"]["id"]
        
        draft_response = client.post(
            "/api/v1/screenplays/draft",
            json={
                "taskId": task_id,
                "prompt": "测试故事",
                "sceneCount": 2,
                "characterCount": 1
            },
            headers=auth_headers
        )
        screenplay_id = draft_response.json()["data"]["id"]
        
        # 更新剧本
        update_data = {
            "title": "更新后的剧本标题"
        }
        
        response = client.put(
            f"/api/v1/screenplays/{screenplay_id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
    
    def test_get_screenplay_not_found(self, client, auth_headers):
        """测试获取不存在的剧本"""
        fake_id = str(uuid4())
        
        response = client.get(
            f"/api/v1/screenplays/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_create_screenplay_requires_auth(self, client):
        """测试创建剧本需要认证"""
        fake_id = str(uuid4())
        response = client.post(
            "/api/v1/screenplays/draft",
            json={
                "taskId": fake_id,
                "prompt": "测试",
                "sceneCount": 1,
                "characterCount": 1
            }
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
