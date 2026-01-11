"""对话API集成测试"""
import pytest
from fastapi import status
from uuid import uuid4


@pytest.mark.integration
@pytest.mark.api
class TestConversationsAPI:
    """对话API测试类"""
    
    def test_create_conversation_success(self, client, auth_headers):
        """测试成功创建对话"""
        conversation_data = {
            "title": "测试对话"
        }
        
        response = client.post(
            "/api/v1/conversations",
            json=conversation_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert data["data"]["title"] == conversation_data["title"]
        assert "id" in data["data"]
    
    def test_get_conversations_list(self, client, auth_headers):
        """测试获取对话列表"""
        # 先创建几个对话
        for i in range(3):
            client.post(
                "/api/v1/conversations",
                json={"title": f"对话 {i+1}"},
                headers=auth_headers
            )
        
        # 获取对话列表
        response = client.get(
            "/api/v1/conversations?page=1&pageSize=10",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "data" in data
        assert "items" in data["data"]
        assert len(data["data"]["items"]) >= 3
    
    def test_get_conversation_detail(self, client, auth_headers):
        """测试获取对话详情"""
        # 先创建对话
        create_response = client.post(
            "/api/v1/conversations",
            json={"title": "测试对话详情"},
            headers=auth_headers
        )
        conversation_id = create_response.json()["data"]["id"]
        
        # 获取对话详情
        response = client.get(
            f"/api/v1/conversations/{conversation_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["id"] == conversation_id
        assert data["data"]["title"] == "测试对话详情"
    
    def test_get_conversation_not_found(self, client, auth_headers):
        """测试获取不存在的对话"""
        fake_id = str(uuid4())
        
        response = client.get(
            f"/api/v1/conversations/{fake_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_update_conversation(self, client, auth_headers):
        """测试更新对话"""
        # 先创建对话
        create_response = client.post(
            "/api/v1/conversations",
            json={"title": "原始标题"},
            headers=auth_headers
        )
        conversation_id = create_response.json()["data"]["id"]
        
        # 更新对话
        update_data = {
            "title": "更新后的标题",
            "isPinned": True
        }
        
        response = client.put(
            f"/api/v1/conversations/{conversation_id}",
            json=update_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["data"]["title"] == "更新后的标题"
    
    def test_delete_conversation(self, client, auth_headers):
        """测试删除对话"""
        # 先创建对话
        create_response = client.post(
            "/api/v1/conversations",
            json={"title": "待删除的对话"},
            headers=auth_headers
        )
        conversation_id = create_response.json()["data"]["id"]
        
        # 删除对话
        response = client.delete(
            f"/api/v1/conversations/{conversation_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        
        # 验证对话已删除
        get_response = client.get(
            f"/api/v1/conversations/{conversation_id}",
            headers=auth_headers
        )
        assert get_response.status_code == status.HTTP_404_NOT_FOUND
    
    def test_get_conversations_requires_auth(self, client):
        """测试获取对话列表需要认证"""
        response = client.get("/api/v1/conversations")
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.integration
@pytest.mark.api
class TestMessagesAPI:
    """消息API测试类"""
    
    def test_create_message_success(self, client, auth_headers):
        """测试成功创建消息"""
        # 先创建对话
        conv_response = client.post(
            "/api/v1/conversations",
            json={"title": "测试对话"},
            headers=auth_headers
        )
        conversation_id = conv_response.json()["data"]["id"]
        
        # 创建消息
        message_data = {
            "role": "user",
            "content": "这是一条测试消息",
            "type": "text"
        }
        
        response = client.post(
            f"/api/v1/conversations/{conversation_id}/messages",
            json=message_data,
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert data["data"]["role"] == "user"
        assert data["data"]["content"] == "这是一条测试消息"
    
    def test_get_messages_list(self, client, auth_headers):
        """测试获取消息列表"""
        # 先创建对话
        conv_response = client.post(
            "/api/v1/conversations",
            json={"title": "测试对话"},
            headers=auth_headers
        )
        conversation_id = conv_response.json()["data"]["id"]
        
        # 创建几条消息
        for i in range(5):
            client.post(
                f"/api/v1/conversations/{conversation_id}/messages",
                json={
                    "role": "user",
                    "content": f"消息 {i+1}",
                    "type": "text"
                },
                headers=auth_headers
            )
        
        # 获取消息列表
        response = client.get(
            f"/api/v1/conversations/{conversation_id}/messages?page=1&pageSize=10",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["code"] == 200
        assert "items" in data["data"]
        assert len(data["data"]["items"]) >= 5
    
    def test_get_message_detail(self, client, auth_headers):
        """测试获取消息详情"""
        # 先创建对话和消息
        conv_response = client.post(
            "/api/v1/conversations",
            json={"title": "测试对话"},
            headers=auth_headers
        )
        conversation_id = conv_response.json()["data"]["id"]
        
        msg_response = client.post(
            f"/api/v1/conversations/{conversation_id}/messages",
            json={
                "role": "user",
                "content": "测试消息内容",
                "type": "text"
            },
            headers=auth_headers
        )
        message_id = msg_response.json()["data"]["id"]
        
        # 获取消息详情
        response = client.get(
            f"/api/v1/conversations/{conversation_id}/messages/{message_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["data"]["id"] == message_id
        assert data["data"]["content"] == "测试消息内容"
    
    def test_delete_message(self, client, auth_headers):
        """测试删除消息"""
        # 先创建对话和消息
        conv_response = client.post(
            "/api/v1/conversations",
            json={"title": "测试对话"},
            headers=auth_headers
        )
        conversation_id = conv_response.json()["data"]["id"]
        
        msg_response = client.post(
            f"/api/v1/conversations/{conversation_id}/messages",
            json={
                "role": "user",
                "content": "待删除的消息",
                "type": "text"
            },
            headers=auth_headers
        )
        message_id = msg_response.json()["data"]["id"]
        
        # 删除消息
        response = client.delete(
            f"/api/v1/conversations/{conversation_id}/messages/{message_id}",
            headers=auth_headers
        )
        
        assert response.status_code == status.HTTP_200_OK
    
    def test_create_message_requires_auth(self, client):
        """测试创建消息需要认证"""
        fake_id = str(uuid4())
        response = client.post(
            f"/api/v1/conversations/{fake_id}/messages",
            json={
                "role": "user",
                "content": "测试",
                "type": "text"
            }
        )
        
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
